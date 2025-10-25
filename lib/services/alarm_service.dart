import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import '../models/alarm.dart' as app_models;

/// アラーム管理サービス
/// alarmパッケージを使用してアラームをスケジュール
class AlarmService {
  /// アラームマネージャーの初期化
  static Future<void> initialize() async {
    await Alarm.init();
  }
  
  /// アラームをスケジュール
  Future<void> scheduleAlarm(app_models.Alarm alarm) async {
    if (!alarm.isEnabled) {
      await cancelAlarm(alarm.id);
      return;
    }
    
    final nextAlarmTime = alarm.getNextAlarmTime();
    debugPrint('🔔 アラームをスケジュール: ID=${alarm.id}, 時刻=$nextAlarmTime');
    
    final alarmSettings = AlarmSettings(
      id: alarm.id,
      dateTime: nextAlarmTime,
      assetAudioPath: 'assets/alarm_sound.mp3',
      loopAudio: true,
      vibrate: true,
      volumeSettings: VolumeSettings.fade(volume: 1.0, fadeDuration: const Duration(seconds: 2)),
      notificationSettings: NotificationSettings(
        title: alarm.label.isNotEmpty ? alarm.label : 'ZapClock',
        body: 'アラームが鳴っています',
        stopButton: '停止',
        icon: 'notification_icon',
      ),
      warningNotificationOnKill: true,
      androidFullScreenIntent: true, // 全画面表示
    );
    
    await Alarm.set(alarmSettings: alarmSettings);
    
    // 繰り返しアラームの場合、次回のスケジュールも設定
    if (alarm.hasRepeat) {
      debugPrint('📅 繰り返しアラームを設定しました');
    }
  }
  
  /// アラームをキャンセル
  Future<void> cancelAlarm(int alarmId) async {
    debugPrint('🔕 アラームをキャンセル: ID=$alarmId');
    await Alarm.stop(alarmId);
  }
  
  /// 全てのアラームを再スケジュール
  Future<void> rescheduleAllAlarms(List<app_models.Alarm> alarms) async {
    for (final alarm in alarms) {
      await scheduleAlarm(alarm);
    }
  }
  
  /// 現在鳴動中のアラームIDを取得
  Future<List<int>> getRingingAlarmIds() async {
    final alarms = await Alarm.getAlarms();
    return alarms.map((alarm) => alarm.id).toList();
  }
  
  /// 指定したIDのアラームが鳴動中かチェック
  Future<bool> isRinging(int alarmId) async {
    final alarms = await Alarm.getAlarms();
    return alarms.any((alarm) => alarm.id == alarmId);
  }
  
  /// アラームを停止
  Future<void> stopAlarm(int alarmId) async {
    debugPrint('⏹️ アラームを停止: ID=$alarmId');
    await Alarm.stop(alarmId);
  }
}
