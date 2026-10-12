import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zap_clock/models/alarm.dart';
import 'package:zap_clock/services/alarm_ring_controller.dart';
import 'package:zap_clock/services/ring_schedule.dart';
import 'package:zap_clock/services/storage_service.dart';
import 'package:zap_clock/services/zap_executor.dart';

import 'fakes.dart';

/// Lets stream events and the controller's awaited futures settle.
Future<void> settle() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const weekdays = [true, true, true, true, true, false, false];
  const nwc = 'nostr+walletconnect://test';

  late FakeAlarmPlatform platform;
  late FakeScheduler scheduler;
  late FakePayer payer;
  late FakeCountdown countdown;
  late StorageService storage;
  late AlarmRingController controller;
  late List<RingEnded> ended;
  late List<int> started;
  late int alarmsChanged;

  Future<void> build({
    List<Alarm> alarms = const [],
    String? nwcConnection = nwc,
    Object? payError,
    int Function(int, int)? pickSnoozeTimeout,
  }) async {
    SharedPreferences.setMockInitialValues({});
    storage = StorageService(await SharedPreferences.getInstance());
    await storage.saveAlarms(List.of(alarms));
    if (nwcConnection != null) {
      await storage.setGlobalNwcConnection(nwcConnection);
    }
    // The bundled preset list is loaded from assets in main(); tests use the
    // global setting as the fallback recipient instead.
    await storage.setDonationRecipient('global@example.com');

    platform = FakeAlarmPlatform();
    scheduler = FakeScheduler();
    payer = FakePayer(error: payError);
    countdown = FakeCountdown();
    ended = [];
    started = [];
    alarmsChanged = 0;

    controller = AlarmRingController(
      platform: platform,
      storage: storage,
      scheduler: scheduler,
      zap: ZapExecutor(storage: storage, payer: payer),
      countdown: countdown,
      onAlarmsChanged: () => alarmsChanged++,
      pickSnoozeTimeout: pickSnoozeTimeout,
    );
    controller.ringStarted.listen(started.add);
    controller.ringEnded.listen(ended.add);
    controller.bind();
    await settle();
  }

  tearDown(() async {
    await controller.dispose();
    await platform.close();
  });

  Alarm stored(int id) => storage.getAlarms().firstWhere((a) => a.id == id);

  group('ring start', () {
    test('starts the countdown with the alarm timeout when a payment is set',
        () async {
      await build(alarms: [
        Alarm(id: 1, hour: 7, minute: 0, amountSats: 21, timeoutSeconds: 90),
      ]);

      platform.ring(1);
      await settle();

      expect(started, [1]);
      expect(controller.ringingIds, {1});
      expect(countdown.running[1]?.timeoutSeconds, 90);
    });

    test('starts no countdown without a payment', () async {
      await build(alarms: [Alarm(id: 1, hour: 7, minute: 0)]);

      platform.ring(1);
      await settle();

      expect(started, [1]);
      expect(countdown.running, isEmpty);
    });

    test('first ring of snooze mode waits for Snooze, no countdown', () async {
      await build(alarms: [
        Alarm(
          id: 1,
          hour: 7,
          minute: 0,
          amountSats: 21,
          enableSnooze: true,
          snoozeCount: 0,
        ),
      ]);

      platform.ring(1);
      await settle();

      expect(countdown.running, isEmpty);
    });

    test('second ring of snooze mode uses a timeout from the snooze range',
        () async {
      await build(
        alarms: [
          Alarm(
            id: 1,
            hour: 7,
            minute: 0,
            amountSats: 21,
            timeoutSeconds: 300,
            enableSnooze: true,
            snoozeCount: 1,
            snoozeTimeoutRange: (3, 30),
          ),
        ],
        pickSnoozeTimeout: (min, max) {
          expect((min, max), (3, 30));
          return 7;
        },
      );

      platform.ring(1);
      await settle();

      expect(countdown.running[1]?.timeoutSeconds, 7);
    });
  });

  group('stop', () {
    test('stops the platform, runs the native backstop, cancels the countdown',
        () async {
      await build(alarms: [
        Alarm(id: 1, hour: 7, minute: 0, amountSats: 21, timeoutSeconds: 90),
      ]);
      platform.ring(1);
      await settle();

      await controller.stop(1);
      await settle();

      expect(platform.stopCalls, [1]);
      expect(platform.backstopCalls, 1);
      expect(countdown.running, isEmpty);
      expect(controller.ringingIds, isEmpty);
      expect(ended.map((e) => (e.alarmId, e.reason)), [(1, StopReason.user)]);
      expect(payer.payments, isEmpty);
    });

    test('runs the backstop even when the plugin did not know it was ringing',
        () async {
      // Emulates issue #11: audio failed, ringingAlarmIds is empty, the service
      // vibrates and Alarm.stop() is a no-op on it.
      await build(alarms: [Alarm(id: 1, hour: 7, minute: 0)]);
      platform.ring(1);
      await settle();
      platform.serviceAlive = true;

      await controller.stop(1);

      expect(platform.backstopCalls, 1);
      expect(platform.serviceAlive, isFalse);
    });

    test('resets snoozeCount and reschedules a repeating alarm for the next '
        'selected day, not timeoutSeconds later (issue #13)', () async {
      await build(alarms: [
        Alarm(
          id: 1,
          hour: 6,
          minute: 30,
          repeatDays: weekdays,
          amountSats: 21,
          timeoutSeconds: 120,
          enableSnooze: true,
          snoozeCount: 1,
        ),
      ]);
      platform.ring(1);
      await settle();

      await controller.stop(1);
      await settle();

      expect(stored(1).snoozeCount, 0);
      expect(scheduler.scheduled.map((a) => a.snoozeCount), [0]);

      final wednesday = DateTime(2026, 10, 14, 7, 0);
      expect(
        nextRingTime(scheduler.scheduled.single, wednesday),
        DateTime(2026, 10, 15, 6, 30),
      );
      expect(alarmsChanged, greaterThan(0));
    });

    test('does not reschedule a one-shot alarm', () async {
      await build(alarms: [Alarm(id: 1, hour: 6, minute: 30)]);
      platform.ring(1);
      await settle();

      await controller.stop(1);

      expect(scheduler.scheduled, isEmpty);
    });

    test('does not reschedule a disabled repeating alarm', () async {
      await build(alarms: [
        Alarm(id: 1, hour: 6, minute: 30, repeatDays: weekdays, isEnabled: false),
      ]);
      platform.ring(1);
      await settle();

      await controller.stop(1);

      expect(scheduler.scheduled, isEmpty);
    });

    test('a second stop while the first is in flight is a no-op', () async {
      await build(alarms: [Alarm(id: 1, hour: 6, minute: 30)]);
      platform.ring(1);
      await settle();

      await Future.wait([controller.stop(1), controller.stop(1)]);
      await settle();

      expect(platform.stopCalls, [1]);
      expect(ended, hasLength(1));
    });
  });

  group('external stop', () {
    test('finalizes once when the platform drops the id (notification Stop)',
        () async {
      await build(alarms: [
        Alarm(
          id: 1,
          hour: 6,
          minute: 30,
          repeatDays: weekdays,
          amountSats: 21,
          timeoutSeconds: 120,
          enableSnooze: true,
          snoozeCount: 1,
        ),
      ]);
      platform.ring(1);
      await settle();

      platform.stopNative(1);
      await settle();

      expect(platform.stopCalls, isEmpty);
      expect(countdown.running, isEmpty);
      expect(controller.ringingIds, isEmpty);
      expect(stored(1).snoozeCount, 0);
      expect(scheduler.scheduled, hasLength(1));
      expect(
        ended.map((e) => (e.alarmId, e.reason)),
        [(1, StopReason.external)],
      );
    });

    test('a countdown that fires after an external stop does nothing',
        () async {
      await build(alarms: [
        Alarm(id: 1, hour: 6, minute: 30, amountSats: 21, timeoutSeconds: 5),
      ]);
      platform.ring(1);
      await settle();
      final onTimeout = countdown.running[1]!.onTimeout;

      platform.stopNative(1);
      await settle();
      await onTimeout();
      await settle();

      expect(payer.payments, isEmpty);
      expect(ended, hasLength(1));
    });
  });

  group('timeout', () {
    test('pays exactly once with the resolved recipient, then stops',
        () async {
      await build(alarms: [
        Alarm(
          id: 1,
          hour: 6,
          minute: 30,
          amountSats: 21,
          timeoutSeconds: 5,
          donationRecipient: 'someone@example.com',
        ),
      ]);
      platform.ring(1);
      await settle();

      await countdown.expire(1);
      await settle();

      expect(payer.payments, hasLength(1));
      expect(payer.payments.single.address, 'someone@example.com');
      expect(payer.payments.single.sats, 21);
      expect(payer.payments.single.connection, nwc);
      expect(platform.stopCalls, [1]);
      expect(platform.backstopCalls, 1);
      expect(ended.single.reason, StopReason.timeout);
      expect(ended.single.zap?.paid, isTrue);
    });

    test('a failed payment is not retried and the alarm still stops',
        () async {
      await build(
        alarms: [
          Alarm(id: 1, hour: 6, minute: 30, amountSats: 21, timeoutSeconds: 5),
        ],
        payError: Exception('wallet offline'),
      );
      platform.ring(1);
      await settle();

      await countdown.expire(1);
      await settle();

      expect(payer.payments, hasLength(1));
      expect(payer.payments.single.address, 'global@example.com');
      expect(platform.stopCalls, [1]);
      expect(ended.single.reason, StopReason.timeout);
      expect(ended.single.zap?.attempted, isTrue);
      expect(ended.single.zap?.paid, isFalse);
    });

    test('without an NWC connection the alarm stops and nothing is paid',
        () async {
      await build(
        alarms: [
          Alarm(id: 1, hour: 6, minute: 30, amountSats: 21, timeoutSeconds: 5),
        ],
        nwcConnection: null,
      );
      platform.ring(1);
      await settle();

      await countdown.expire(1);
      await settle();

      expect(payer.payments, isEmpty);
      expect(platform.stopCalls, [1]);
      expect(ended.single.zap?.attempted, isFalse);
    });

    test('a user stop racing the timeout results in one stop and no double '
        'finalize', () async {
      await build(alarms: [
        Alarm(id: 1, hour: 6, minute: 30, amountSats: 21, timeoutSeconds: 5),
      ]);
      platform.ring(1);
      await settle();

      final timeout = countdown.expire(1);
      final stop = controller.stop(1);
      await Future.wait([timeout, stop]);
      await settle();

      expect(platform.stopCalls, [1]);
      expect(ended, hasLength(1));
    });
  });

  group('reschedule failure', () {
    test('still ends the ring and keeps later stops working', () async {
      await build(alarms: [
        Alarm(id: 1, hour: 6, minute: 30, repeatDays: weekdays),
      ]);
      scheduler.error = StateError('AlarmManager unavailable');
      platform.ring(1);
      await settle();

      await controller.stop(1);
      await settle();

      expect(ended.map((e) => e.reason), [StopReason.user]);
      expect(controller.ringingIds, isEmpty);

      // A new ring of the same id must be stoppable again.
      scheduler.error = null;
      platform.ring(1);
      await settle();
      await controller.stop(1);
      await settle();

      expect(ended, hasLength(2));
      expect(platform.stopCalls, [1, 1]);
    });
  });

  group('after the ring ended', () {
    test('stop and snooze are no-ops and schedule nothing', () async {
      await build(alarms: [
        Alarm(
          id: 1,
          hour: 6,
          minute: 30,
          repeatDays: weekdays,
          amountSats: 21,
          enableSnooze: true,
          snoozeCount: 0,
        ),
      ]);
      platform.ring(1);
      await settle();
      platform.stopNative(1);
      await settle();
      final scheduledAfterExternalStop = scheduler.scheduled.length;

      await controller.stop(1);
      await controller.snooze(1);
      await settle();

      expect(platform.stopCalls, isEmpty);
      expect(scheduler.scheduled, hasLength(scheduledAfterExternalStop));
      expect(stored(1).snoozeCount, 0);
      expect(ended, hasLength(1));
    });
  });

  group('snooze', () {
    test('silences, sets snoozeCount to 1, schedules the second ring, no zap',
        () async {
      await build(alarms: [
        Alarm(
          id: 1,
          hour: 6,
          minute: 30,
          repeatDays: weekdays,
          amountSats: 21,
          timeoutSeconds: 120,
          enableSnooze: true,
          snoozeCount: 0,
        ),
      ]);
      platform.ring(1);
      await settle();

      await controller.snooze(1);
      await settle();

      expect(platform.stopCalls, [1]);
      expect(platform.backstopCalls, 1);
      expect(stored(1).snoozeCount, 1);
      expect(scheduler.scheduled.single.snoozeCount, 1);
      expect(payer.payments, isEmpty);
      expect(ended.single.reason, StopReason.snooze);
      expect(controller.ringingIds, isEmpty);

      final wednesday = DateTime(2026, 10, 14, 7, 0);
      expect(
        nextRingTime(scheduler.scheduled.single, wednesday),
        wednesday.add(const Duration(seconds: 120)),
      );
    });
  });
}
