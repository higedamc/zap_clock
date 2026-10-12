import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zap_clock/models/alarm.dart';
import 'package:zap_clock/models/zap_obligation.dart';
import 'package:zap_clock/services/alarm_ring_controller.dart';
import 'package:zap_clock/services/ring_schedule.dart';
import 'package:zap_clock/services/storage_service.dart';
import 'package:zap_clock/services/zap_executor.dart';
import 'package:zap_clock/services/zap_ledger.dart';

import 'fakes.dart';

/// Lets stream events and the controller's awaited futures settle.
Future<void> settle() async {
  for (var i = 0; i < 25; i++) {
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
  late ZapLedger ledger;
  late FakeJournal journal;
  late DateTime now;
  late AlarmRingController controller;
  late List<RingEnded> ended;
  late List<int> started;
  late int alarmsChanged;

  Future<void> build({
    List<Alarm> alarms = const [],
    String? nwcConnection = nwc,
    Object? payError,
    int Function(int, int)? pickSnoozeTimeout,
    FakePayer? payerOverride,
    void Function(ZapLedger ledger)? seedLedger,
    void Function(FakeJournal journal)? seedJournal,
    List<int> initiallyRinging = const [],
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    storage = StorageService(prefs);
    ledger = ZapLedger(prefs);
    journal = FakeJournal();
    now = DateTime(2026, 10, 14, 7, 0);
    await storage.saveAlarms(List.of(alarms));
    if (nwcConnection != null) {
      await storage.setGlobalNwcConnection(nwcConnection);
    }
    // The bundled preset list is loaded from assets in main(); tests use the
    // global setting as the fallback recipient instead.
    await storage.setDonationRecipient('global@example.com');

    seedLedger?.call(ledger);
    // The native journal exists before the engine starts; seed it before
    // bind(), whose first platform event already settles overdue entries.
    seedJournal?.call(journal);

    platform = FakeAlarmPlatform();
    // Alarms already ringing when the engine starts (Alarm.init seeds the
    // plugin's ringing set before anyone listens).
    for (final id in initiallyRinging) {
      platform.ring(id);
    }
    scheduler = FakeScheduler();
    payer = payerOverride ?? FakePayer(error: payError);
    countdown = FakeCountdown();
    ended = [];
    started = [];
    alarmsChanged = 0;

    controller = AlarmRingController(
      platform: platform,
      storage: storage,
      scheduler: scheduler,
      zap: ZapExecutor(storage: storage, payer: payer),
      ledger: ledger,
      journal: journal,
      countdown: countdown,
      onAlarmsChanged: () => alarmsChanged++,
      pickSnoozeTimeout: pickSnoozeTimeout,
      clock: () => now,
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

  group('ledger', () {
    Alarm paidAlarm() =>
        Alarm(id: 1, hour: 7, minute: 0, amountSats: 21, timeoutSeconds: 90);

    test('ring start uses the reserved obligation deadline, not the alarm '
        'timeout', () async {
      await build(
        alarms: [paidAlarm()],
        seedLedger: (l) => l.reserve(
          alarm: paidAlarm().copyWith(timeoutSeconds: 90),
          ringAt: DateTime(2026, 10, 14, 7, 0),
          resolveRecipient: (_) => 'reserved@example.com',
          pickSnoozeTimeout: (a, b) => a,
        ),
      );
      // Clock is 07:00, deadline is 07:01:30; the engine came up 20 s late.
      now = DateTime(2026, 10, 14, 7, 0, 20);

      platform.ring(1);
      await settle();

      expect(countdown.running[1]?.timeoutSeconds, 70);
    });

    test('a ring with no reservation gets one at ring time (migration)',
        () async {
      await build(alarms: [paidAlarm()]);

      platform.ring(1);
      await settle();

      final pending = ledger.pending().single;
      expect(pending.alarmId, 1);
      expect(pending.ringAt, now);
      expect(pending.deadline, now.add(const Duration(seconds: 90)));
      expect(pending.recipient, 'global@example.com');
      expect(countdown.running[1]?.timeoutSeconds, 90);
    });

    test('attempted is written before the wallet is called', () async {
      final peeking = LedgerPeekingPayer(
        () => ledger.pending().isEmpty
            ? ledger.all().single.status.name
            : 'pending',
      );
      await build(alarms: [paidAlarm()], payerOverride: peeking);
      platform.ring(1);
      await settle();

      await countdown.expire(1);
      await settle();

      expect(peeking.statusesSeen, ['attempted']);
      expect(ledger.all().single.status, ZapObligationStatus.paid);
      expect(ledger.all().single.paymentHash, 'hash-1');
    });

    test('pays the amount and recipient frozen in the obligation, not the '
        'edited alarm', () async {
      await build(
        alarms: [paidAlarm()],
        seedLedger: (l) => l.reserve(
          alarm: paidAlarm().copyWith(amountSats: 5),
          ringAt: DateTime(2026, 10, 14, 7, 0),
          resolveRecipient: (_) => 'frozen@example.com',
          pickSnoozeTimeout: (a, b) => a,
        ),
      );
      platform.ring(1);
      await settle();

      await countdown.expire(1);
      await settle();

      expect(payer.payments.single.sats, 5);
      expect(payer.payments.single.address, 'frozen@example.com');
    });

    test('a failed payment is recorded as failed and never retried, even if '
        'the ring fires again', () async {
      await build(alarms: [paidAlarm()], payError: Exception('offline'));
      platform.ring(1);
      await settle();
      await countdown.expire(1);
      await settle();

      expect(ledger.all().single.status, ZapObligationStatus.failed);
      expect(ledger.pending(), isEmpty);

      // The same alarm rings again later (new obligation), the old one must
      // stay failed and untouched.
      now = now.add(const Duration(hours: 24));
      platform.ring(1);
      await settle();
      await controller.stop(1);
      await settle();

      expect(payer.payments, hasLength(1));
      expect(
        ledger.all().map((o) => o.status),
        unorderedEquals([
          ZapObligationStatus.failed,
          ZapObligationStatus.cancelled,
        ]),
      );
    });

    test('stop before the deadline cancels the obligation', () async {
      await build(alarms: [paidAlarm()]);
      platform.ring(1);
      await settle();

      await controller.stop(1);
      await settle();

      expect(ledger.all().single.status, ZapObligationStatus.cancelled);
      expect(payer.payments, isEmpty);
    });

    test('external stop before the deadline cancels the obligation',
        () async {
      await build(alarms: [paidAlarm()]);
      platform.ring(1);
      await settle();

      platform.stopNative(1);
      await settle();

      expect(ledger.all().single.status, ZapObligationStatus.cancelled);
    });

    test('engine starting after the deadline while the alarm is still '
        'ringing pays once and stops', () async {
      // Deadline 06:51:30, engine comes up at 07:00 with the alarm ringing
      // and no journal (the service never stopped, so there is no stop entry).
      await build(
        alarms: [paidAlarm()],
        seedLedger: (l) => l.reserve(
          alarm: paidAlarm(),
          ringAt: DateTime(2026, 10, 14, 6, 50),
          resolveRecipient: (_) => 'r@example.com',
          pickSnoozeTimeout: (a, b) => a,
        ),
        initiallyRinging: [1],
      );

      expect(payer.payments, hasLength(1));
      expect(platform.stopCalls, [1]);
      expect(ledger.all().single.status, ZapObligationStatus.paid);
      expect(ended.single.reason, StopReason.timeout);
    });
  });

  group('settleOverdue (engine was dead at the deadline)', () {
    final ringAt = DateTime(2026, 10, 14, 6, 0);
    final deadline = ringAt.add(const Duration(seconds: 90));
    Alarm paidAlarm() =>
        Alarm(id: 1, hour: 6, minute: 0, amountSats: 21, timeoutSeconds: 90);

    /// Builds with the obligation overdue and the native journal pre-filled,
    /// as it would be when the app starts after a ring it did not see.
    /// bind() in build() delivers the initial ringing set, which triggers
    /// settleOverdue() on its own.
    Future<void> buildOverdue(void Function(FakeJournal j) seed) => build(
          alarms: [paidAlarm()],
          seedLedger: (l) => l.reserve(
            alarm: paidAlarm(),
            ringAt: ringAt,
            resolveRecipient: (_) => 'r@example.com',
            pickSnoozeTimeout: (a, b) => a,
          ),
          seedJournal: seed,
        );

    test('stopped from the notification after the deadline: pays once, '
        'settled automatically on start and idempotent afterwards', () async {
      await buildOverdue((j) {
        j.start(ringAt);
        j.stop(deadline.add(const Duration(seconds: 40)));
      });

      expect(payer.payments, hasLength(1));

      await controller.settleOverdue();
      await controller.settleOverdue();

      expect(payer.payments, hasLength(1));
      expect(ledger.all().single.status, ZapObligationStatus.paid);
      expect(platform.stopCalls, isEmpty);
    });

    test('stopped from the notification before the deadline: cancelled, '
        'nothing paid', () async {
      await buildOverdue((j) {
        j.start(ringAt);
        j.stop(ringAt.add(const Duration(seconds: 10)));
      });

      expect(payer.payments, isEmpty);
      expect(ledger.all().single.status, ZapObligationStatus.cancelled);
    });

    test('no journal record: unprovable, nothing paid', () async {
      await buildOverdue((_) {});

      expect(payer.payments, isEmpty);
      expect(ledger.all().single.status, ZapObligationStatus.unprovable);
    });

    test('ring started but never stopped and not ringing now (process '
        'killed): unprovable', () async {
      await buildOverdue((j) => j.start(ringAt));

      expect(payer.payments, isEmpty);
      expect(ledger.all().single.status, ZapObligationStatus.unprovable);
    });

    test('a throw inside settlement is logged, not propagated, and the next '
        'call still settles', () async {
      // bind() in build() already ran one settleOverdue(); make the journal
      // throw only for the explicit calls below.
      await build(alarms: [paidAlarm()]);
      await ledger.reserve(
        alarm: paidAlarm(),
        ringAt: ringAt,
        resolveRecipient: (_) => 'r@example.com',
        pickSnoozeTimeout: (a, b) => a,
      );
      journal.start(ringAt);
      journal.stop(deadline.add(const Duration(seconds: 40)));
      now = deadline.add(const Duration(hours: 1));

      journal.readError = StateError('platform channel gone');
      await expectLater(controller.settleOverdue(), completes);
      expect(payer.payments, isEmpty);
      expect(ledger.pending(), hasLength(1), reason: 'undecided, stays pending');

      journal.readError = null;
      await controller.settleOverdue();

      expect(payer.payments, hasLength(1));
      expect(ledger.pending(), isEmpty);
    });

    test('a start after the deadline from an unrelated ring pays nothing',
        () async {
      // The reserved 06:00 ring never happened; a different alarm rang at
      // 09:00 and was stopped normally. Its stop is past the stale deadline
      // but must not settle this obligation (review blocker on #17).
      await buildOverdue((j) {
        j.start(ringAt.add(const Duration(hours: 3)));
        j.stop(ringAt.add(const Duration(hours: 3, minutes: 1)));
      });

      expect(payer.payments, isEmpty);
      expect(ledger.all().single.status, ZapObligationStatus.unprovable);
    });

    test('a journal that fails to read pays nothing', () async {
      await buildOverdue((j) {
        j.start(ringAt);
        j.stop(deadline.add(const Duration(seconds: 40)));
      });
      // Already paid above; now make sure a second, new obligation with a
      // journal read failure is not paid.
      await ledger.reserve(
        alarm: paidAlarm(),
        ringAt: ringAt.add(const Duration(days: 1)),
        resolveRecipient: (_) => 'r@example.com',
        pickSnoozeTimeout: (a, b) => a,
      );
      now = ringAt.add(const Duration(days: 1, hours: 1));
      journal.entries.clear();

      await controller.settleOverdue();

      expect(payer.payments, hasLength(1));
      expect(ledger.pending(), isEmpty);
      expect(
        ledger.all().where((o) => o.status == ZapObligationStatus.unprovable),
        hasLength(1),
      );
    });

    test('a deadline still ahead is left alone', () async {
      await build(
        alarms: [paidAlarm()],
        seedLedger: (l) => l.reserve(
          alarm: paidAlarm(),
          ringAt: DateTime(2026, 10, 14, 7, 30),
          resolveRecipient: (_) => 'r@example.com',
          pickSnoozeTimeout: (a, b) => a,
        ),
      );

      await controller.settleOverdue();

      expect(payer.payments, isEmpty);
      expect(ledger.pending(), hasLength(1));
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
