import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/alarm.dart';

/// ローカルストレージサービス
/// SharedPreferencesを使用してアラームデータを永続化
class StorageService {
  static const String _alarmsKey = 'alarms';
  static const String _nextIdKey = 'next_alarm_id';
  static const String _globalNwcConnectionKey = 'global_nwc_connection';
  static const String _hasCompletedOnboardingKey = 'has_completed_onboarding';
  
  final SharedPreferences _prefs;
  
  StorageService(this._prefs);
  
  /// 全てのアラームを取得
  List<Alarm> getAlarms() {
    final alarmsJson = _prefs.getString(_alarmsKey);
    if (alarmsJson == null) {
      return [];
    }
    
    try {
      final List<dynamic> decoded = json.decode(alarmsJson);
      return decoded.map((json) => Alarm.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }
  
  /// 全てのアラームを保存
  Future<bool> saveAlarms(List<Alarm> alarms) async {
    final alarmsJson = json.encode(
      alarms.map((alarm) => alarm.toJson()).toList(),
    );
    return await _prefs.setString(_alarmsKey, alarmsJson);
  }
  
  /// アラームを追加
  Future<bool> addAlarm(Alarm alarm) async {
    final alarms = getAlarms();
    alarms.add(alarm);
    return await saveAlarms(alarms);
  }
  
  /// アラームを更新
  Future<bool> updateAlarm(Alarm alarm) async {
    final alarms = getAlarms();
    final index = alarms.indexWhere((a) => a.id == alarm.id);
    
    if (index == -1) {
      return false;
    }
    
    alarms[index] = alarm;
    return await saveAlarms(alarms);
  }
  
  /// アラームを削除
  Future<bool> deleteAlarm(int alarmId) async {
    final alarms = getAlarms();
    alarms.removeWhere((alarm) => alarm.id == alarmId);
    return await saveAlarms(alarms);
  }
  
  /// 次のアラームIDを取得
  int getNextAlarmId() {
    final nextId = _prefs.getInt(_nextIdKey) ?? 1;
    return nextId;
  }
  
  /// 次のアラームIDをインクリメント
  Future<int> incrementNextAlarmId() async {
    final nextId = getNextAlarmId();
    await _prefs.setInt(_nextIdKey, nextId + 1);
    return nextId;
  }
  
  /// 全データをクリア（デバッグ用）
  Future<bool> clearAll() async {
    await _prefs.remove(_alarmsKey);
    await _prefs.remove(_nextIdKey);
    return true;
  }
  
  // === グローバルNWC設定 ===
  
  /// グローバルNWC接続文字列を取得
  String? getGlobalNwcConnection() {
    return _prefs.getString(_globalNwcConnectionKey);
  }
  
  /// グローバルNWC接続文字列を保存
  Future<bool> setGlobalNwcConnection(String connection) async {
    return await _prefs.setString(_globalNwcConnectionKey, connection);
  }
  
  // === オンボーディング ===
  
  /// オンボーディング完了フラグを取得
  bool hasCompletedOnboarding() {
    return _prefs.getBool(_hasCompletedOnboardingKey) ?? false;
  }
  
  /// オンボーディング完了フラグを設定
  Future<bool> setOnboardingCompleted() async {
    return await _prefs.setBool(_hasCompletedOnboardingKey, true);
  }
}

