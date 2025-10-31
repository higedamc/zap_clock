import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alarm/alarm.dart';
import '../models/alarm.dart' as app_models;
import 'storage_service.dart';
import 'nwc_service.dart';
import '../models/donation_recipient.dart';

/// アラームのバックグラウンドカウントダウンを管理するサービス
class AlarmCountdownService {
  static final AlarmCountdownService _instance = AlarmCountdownService._internal();
  factory AlarmCountdownService() => _instance;
  AlarmCountdownService._internal();

  final Map<int, Timer> _countdownTimers = {};
  final Map<int, DateTime> _startTimes = {};
  final Map<int, int> _timeoutSeconds = {};
  
  static const String _keyPrefix = 'alarm_countdown_';
  
  /// アラームが鳴り始めたときに呼び出す
  /// カウントダウンを開始し、タイムアウト時に自動Zap処理を実行
  Future<void> startCountdown({
    required int alarmId,
    required app_models.Alarm alarm,
    required StorageService storageService,
    required NwcService nwcService,
  }) async {
    // 既存のタイマーをキャンセル
    stopCountdown(alarmId);
    
    // 送金設定がない場合はカウントダウン不要
    if (alarm.amountSats == null) {
      debugPrint('⏱️ アラームID=$alarmId: 送金設定なし、カウントダウンスキップ');
      return;
    }
    
    final timeoutSeconds = alarm.timeoutSeconds ?? 300;
    final startTime = DateTime.now();
    
    // 開始時刻とタイムアウト秒数を保存（メモリとSharedPreferences両方）
    _startTimes[alarmId] = startTime;
    _timeoutSeconds[alarmId] = timeoutSeconds;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('${_keyPrefix}${alarmId}_start', startTime.millisecondsSinceEpoch);
    await prefs.setInt('${_keyPrefix}${alarmId}_timeout', timeoutSeconds);
    
    debugPrint('⏱️ アラームID=$alarmId: カウントダウン開始 (${timeoutSeconds}秒)');
    
    // バックグラウンドでタイムアウトを監視
    final timer = Timer(Duration(seconds: timeoutSeconds), () async {
      debugPrint('⏰ アラームID=$alarmId: タイムアウト到達！自動Zap処理を開始');
      await _executeAutoZap(
        alarmId: alarmId,
        alarm: alarm,
        storageService: storageService,
        nwcService: nwcService,
      );
    });
    
    _countdownTimers[alarmId] = timer;
  }
  
  /// カウントダウンを停止（手動でアラームを止めた場合）
  void stopCountdown(int alarmId) async {
    _countdownTimers[alarmId]?.cancel();
    _countdownTimers.remove(alarmId);
    _startTimes.remove(alarmId);
    _timeoutSeconds.remove(alarmId);
    
    // SharedPreferencesからも削除
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('${_keyPrefix}${alarmId}_start');
    await prefs.remove('${_keyPrefix}${alarmId}_timeout');
    
    debugPrint('⏹️ アラームID=$alarmId: カウントダウン停止');
  }
  
  /// 残り時間を取得（秒）
  Future<int?> getRemainingSeconds(int alarmId) async {
    // メモリ内の開始時刻とタイムアウト秒数を優先
    DateTime? startTime = _startTimes[alarmId];
    int? timeoutSeconds = _timeoutSeconds[alarmId];
    
    // メモリになければSharedPreferencesから取得
    if (startTime == null || timeoutSeconds == null) {
      final prefs = await SharedPreferences.getInstance();
      final startMillis = prefs.getInt('${_keyPrefix}${alarmId}_start');
      final storedTimeout = prefs.getInt('${_keyPrefix}${alarmId}_timeout');
      
      if (startMillis == null || storedTimeout == null) {
        debugPrint('⚠️ アラームID=$alarmId: カウントダウンデータが見つかりません');
        return null; // カウントダウン未開始
      }
      
      startTime = DateTime.fromMillisecondsSinceEpoch(startMillis);
      timeoutSeconds = storedTimeout;
      
      // メモリにキャッシュ
      _startTimes[alarmId] = startTime;
      _timeoutSeconds[alarmId] = timeoutSeconds;
      
      debugPrint('📱 アラームID=$alarmId: SharedPreferencesから復元 (開始: $startTime, タイムアウト: ${timeoutSeconds}秒)');
    }
    
    final elapsed = DateTime.now().difference(startTime).inSeconds;
    final remaining = timeoutSeconds - elapsed;
    
    // デバッグログは頻繁に呼ばれるので簡略化
    if (remaining % 10 == 0 || remaining <= 10) {
      debugPrint('⏱️ アラームID=$alarmId: 残り${remaining}秒');
    }
    
    return remaining > 0 ? remaining : 0;
  }
  
  /// カウントダウン開始時刻を取得
  Future<DateTime?> getStartTime(int alarmId) async {
    // メモリ内の開始時刻を優先
    if (_startTimes.containsKey(alarmId)) {
      return _startTimes[alarmId];
    }
    
    // SharedPreferencesから取得
    final prefs = await SharedPreferences.getInstance();
    final startMillis = prefs.getInt('${_keyPrefix}${alarmId}_start');
    if (startMillis == null) return null;
    
    return DateTime.fromMillisecondsSinceEpoch(startMillis);
  }
  
  /// 自動Zap処理を実行
  Future<void> _executeAutoZap({
    required int alarmId,
    required app_models.Alarm alarm,
    required StorageService storageService,
    required NwcService nwcService,
  }) async {
    try {
      // NWC接続文字列を取得
      final nwcConnection = storageService.getGlobalNwcConnection();
      
      if (nwcConnection == null || nwcConnection.isEmpty) {
        debugPrint('⚠️ アラームID=$alarmId: NWC接続が設定されていません');
        // NWC設定がなくてもアラームは停止
        await Alarm.stop(alarmId);
        await _cleanupAfterAlarm(alarmId, alarm, storageService);
        return;
      }
      
      // 送金先を取得
      final recipientAddress = alarm.donationRecipient 
          ?? storageService.getDonationRecipient() 
          ?? DonationRecipients.defaultRecipientSync.lightningAddress;
      
      debugPrint('💳 アラームID=$alarmId: NWC経由で自動送金を開始');
      debugPrint('📍 送金先: $recipientAddress');
      debugPrint('💰 金額: ${alarm.amountSats} sats');
      
      // Lightning送金を実行
      final paymentHash = await nwcService.payWithNwc(
        connectionString: nwcConnection,
        lightningAddress: recipientAddress,
        amountSats: alarm.amountSats!,
        comment: 'donation from ZapClock',
      );
      
      debugPrint('✅ アラームID=$alarmId: 自動送金成功 ($paymentHash)');
      
      // アラームを停止
      await Alarm.stop(alarmId);
      await _cleanupAfterAlarm(alarmId, alarm, storageService);
      
    } catch (e) {
      debugPrint('❌ アラームID=$alarmId: 自動送金エラー: $e');
      
      // 送金失敗してもアラームは停止
      await Alarm.stop(alarmId);
      await _cleanupAfterAlarm(alarmId, alarm, storageService);
    }
  }
  
  /// アラーム停止後のクリーンアップ処理
  Future<void> _cleanupAfterAlarm(
    int alarmId,
    app_models.Alarm alarm,
    StorageService storageService,
  ) async {
    // カウントダウンデータを削除
    stopCountdown(alarmId);
    
    // 繰り返しアラームの場合は次回をスケジュール
    if (alarm.hasRepeat && alarm.isEnabled) {
      debugPrint('🔄 アラームID=$alarmId: 繰り返しアラーム、次回をスケジュール');
      // Note: これはAlarmServiceを通じて行うべきだが、
      // ここではシンプルにするため、次回は画面側で処理させる
    }
    
    debugPrint('✅ アラームID=$alarmId: クリーンアップ完了');
  }
  
  /// すべてのカウントダウンを停止
  void stopAllCountdowns() {
    final alarmIds = _countdownTimers.keys.toList();
    for (final alarmId in alarmIds) {
      stopCountdown(alarmId);
    }
    debugPrint('🛑 すべてのカウントダウンを停止しました');
  }
}

