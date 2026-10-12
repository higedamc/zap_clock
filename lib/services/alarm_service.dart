import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import '../models/alarm.dart' as app_models;
import 'alarm_ring_controller.dart';
import 'ring_schedule.dart';

/// Alarm management service
/// Schedule alarms using the alarm package
class AlarmService implements AlarmScheduler {
  /// Initialize alarm manager
  static Future<void> initialize() async {
    await Alarm.init();
  }
  
  /// Schedule an alarm
  @override
  Future<void> scheduleAlarm(app_models.Alarm alarm) async {
    if (!alarm.isEnabled) {
      await cancelAlarm(alarm.id);
      return;
    }
    
    final nextAlarmTime = nextRingTime(alarm, DateTime.now());
    
    debugPrint('🔔 Scheduling alarm: ID=${alarm.id}, time=$nextAlarmTime, snoozeCount=${alarm.snoozeCount}');
    
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
        body: (alarm.enableSnooze && alarm.snoozeCount == 1) 
            ? '2nd alarm - Stop quickly!'
            : 'Alarm is ringing',
        stopButton: 'Stop',
        icon: 'notification_icon',
      ),
      warningNotificationOnKill: true,
      // Lock-screen bypass depends on this flag. The alarm plugin only publishes
      // AlarmRingingLiveData(true) when androidFullScreenIntent is set
      // (alarm 5.4.1 AlarmService.kt:125-127), and that LiveData is what sets
      // showWhenLocked/turnScreenOn for the ringing window. The manifest no longer
      // carries those flags, so turning this off silently stops alarms from
      // showing over the lock screen (issues #8, #12).
      androidFullScreenIntent: true,
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
  
  // getRingingAlarmIds() / isRinging() / stopAlarm() were removed on purpose.
  // The first two returned the *scheduled* list (Alarm.getAlarms()), so
  // isRinging was true whenever any alarm was enabled. Ringing state is owned
  // by AlarmRingController, and stopping goes through it as well.
}
