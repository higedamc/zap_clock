import '../models/alarm.dart';

/// Pure scheduling rule shared by [AlarmService] and the unit tests.
///
/// The second ring of a snooze-mode alarm (`snoozeCount == 1`) fires
/// `timeoutSeconds` after it is scheduled. Everything else, including a
/// snooze-mode alarm whose count has been reset to 0, fires at the next
/// matching wall-clock time.
DateTime nextRingTime(Alarm alarm, DateTime now) {
  if (alarm.enableSnooze && alarm.snoozeCount == 1) {
    return now.add(Duration(seconds: alarm.timeoutSeconds ?? 300));
  }
  return alarm.getNextAlarmTime(now: now);
}
