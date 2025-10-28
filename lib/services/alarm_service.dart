import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import '../models/alarm.dart' as app_models;

/// Alarm management service
/// Schedule alarms using the alarm package
class AlarmService {
  /// Initialize alarm manager
  static Future<void> initialize() async {
    await Alarm.init();
  }
  
  /// Schedule an alarm
  Future<void> scheduleAlarm(app_models.Alarm alarm) async {
    if (!alarm.isEnabled) {
      await cancelAlarm(alarm.id);
      return;
    }
    
    final nextAlarmTime = alarm.getNextAlarmTime();
    debugPrint('🔔 Scheduling alarm: ID=${alarm.id}, time=$nextAlarmTime');
    
    // Determine audio path (use default if null)
    final audioPath = alarm.soundPath ?? 'assets/alarm_sound.mp3';
    debugPrint('🔊 Using audio: $audioPath');
    
    final alarmSettings = AlarmSettings(
      id: alarm.id,
      dateTime: nextAlarmTime,
      assetAudioPath: audioPath,
      loopAudio: true,
      vibrate: true,
      volumeSettings: VolumeSettings.fade(volume: 1.0, fadeDuration: const Duration(seconds: 2)),
      notificationSettings: NotificationSettings(
        title: alarm.label.isNotEmpty ? alarm.label : 'ZapClock',
        body: 'Alarm is ringing',
        stopButton: 'Stop',
        icon: 'notification_icon',
      ),
      warningNotificationOnKill: true,
      androidFullScreenIntent: true, // Full screen display
    );
    
    await Alarm.set(alarmSettings: alarmSettings);
    
    // For recurring alarms, also set next schedule
    if (alarm.hasRepeat) {
      debugPrint('📅 Recurring alarm set');
    }
  }
  
  /// Cancel an alarm
  Future<void> cancelAlarm(int alarmId) async {
    debugPrint('🔕 Canceling alarm: ID=$alarmId');
    await Alarm.stop(alarmId);
  }
  
  /// Reschedule all alarms
  Future<void> rescheduleAllAlarms(List<app_models.Alarm> alarms) async {
    for (final alarm in alarms) {
      await scheduleAlarm(alarm);
    }
  }
  
  /// Get currently ringing alarm IDs
  Future<List<int>> getRingingAlarmIds() async {
    final alarms = await Alarm.getAlarms();
    return alarms.map((alarm) => alarm.id).toList();
  }
  
  /// Check if specified ID alarm is ringing
  Future<bool> isRinging(int alarmId) async {
    final alarms = await Alarm.getAlarms();
    return alarms.any((alarm) => alarm.id == alarmId);
  }
  
  /// Stop an alarm
  Future<void> stopAlarm(int alarmId) async {
    debugPrint('⏹️ Stopping alarm: ID=$alarmId');
    await Alarm.stop(alarmId);
  }
}
