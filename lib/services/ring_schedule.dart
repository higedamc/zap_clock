import 'dart:math';

import '../models/alarm.dart';

/// Draws the second snooze ring's timeout from the alarm's range, inclusive.
/// Not security relevant, so a plain Random is fine.
int defaultSnoozeTimeoutPicker(int minSeconds, int maxSeconds) {
  if (maxSeconds <= minSeconds) return minSeconds;
  return minSeconds + Random().nextInt(maxSeconds - minSeconds + 1);
}

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
