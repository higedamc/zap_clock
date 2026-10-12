import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import '../models/alarm.dart' as app_models;
import 'alarm_ring_controller.dart';
import 'ring_schedule.dart';
import 'zap_ledger.dart';

/// Alarm management service
/// Schedule alarms using the alarm package
class AlarmService implements AlarmScheduler {
  AlarmService({
    ZapLedger? ledger,
    String Function(app_models.Alarm alarm)? resolveRecipient,
    int Function(int minSeconds, int maxSeconds)? pickSnoozeTimeout,
  })  : _ledger = ledger,
        _resolveRecipient = resolveRecipient,
        _pickSnoozeTimeout = pickSnoozeTimeout ?? defaultSnoozeTimeoutPicker;

  final ZapLedger? _ledger;
  final String Function(app_models.Alarm alarm)? _resolveRecipient;
  final int Function(int minSeconds, int maxSeconds) _pickSnoozeTimeout;

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
    
    // The zap this ring may owe is reserved now, keyed by alarm id and ring
    // time, with its deadline fixed. The ring screen only displays it.
    final ledger = _ledger;
    final resolveRecipient = _resolveRecipient;
    if (ledger != null && resolveRecipient != null) {
      await ledger.reserve(
        alarm: alarm,
        ringAt: nextAlarmTime,
        resolveRecipient: resolveRecipient,
        pickSnoozeTimeout: _pickSnoozeTimeout,
      );
    }
    
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
    await _ledger?.cancelPendingFor(alarmId);
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
