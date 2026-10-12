import 'package:flutter_test/flutter_test.dart';
import 'package:zap_clock/models/alarm.dart';
import 'package:zap_clock/services/ring_schedule.dart';

void main() {
  // Wednesday 2026-10-14 07:00 local time.
  final wednesday = DateTime(2026, 10, 14, 7, 0);
  final weekdays = [true, true, true, true, true, false, false];

  group('nextRingTime', () {
    test('second snooze ring fires timeoutSeconds after now', () {
      final alarm = Alarm(
        id: 1,
        hour: 6,
        minute: 30,
        repeatDays: weekdays,
        amountSats: 21,
        timeoutSeconds: 120,
        enableSnooze: true,
        snoozeCount: 1,
      );

      expect(
        nextRingTime(alarm, wednesday),
        wednesday.add(const Duration(seconds: 120)),
      );
    });

    test('snooze-mode alarm with count reset rings on the next selected day',
        () {
      final alarm = Alarm(
        id: 1,
        hour: 6,
        minute: 30,
        repeatDays: weekdays,
        amountSats: 21,
        timeoutSeconds: 120,
        enableSnooze: true,
        snoozeCount: 0,
      );

      // 06:30 already passed on Wednesday, so Thursday 06:30.
      expect(nextRingTime(alarm, wednesday), DateTime(2026, 10, 15, 6, 30));
    });

    test('weekday-only alarm skips the weekend', () {
      final alarm = Alarm(id: 1, hour: 6, minute: 30, repeatDays: weekdays);
      final friday = DateTime(2026, 10, 16, 7, 0);

      expect(nextRingTime(alarm, friday), DateTime(2026, 10, 19, 6, 30));
    });

    test('one-shot alarm whose time passed today rings tomorrow', () {
      final alarm = Alarm(id: 1, hour: 6, minute: 30);

      expect(nextRingTime(alarm, wednesday), DateTime(2026, 10, 15, 6, 30));
    });

    test('one-shot alarm still ahead today rings today', () {
      final alarm = Alarm(id: 1, hour: 8, minute: 0);

      expect(nextRingTime(alarm, wednesday), DateTime(2026, 10, 14, 8, 0));
    });
  });
}
