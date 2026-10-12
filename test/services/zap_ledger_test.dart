import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zap_clock/models/alarm.dart';
import 'package:zap_clock/models/zap_obligation.dart';
import 'package:zap_clock/services/zap_ledger.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final ringAt = DateTime(2026, 10, 14, 7, 0);
  late ZapLedger ledger;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    ledger = ZapLedger(await SharedPreferences.getInstance());
  });

  Future<ZapObligation?> reserve(Alarm alarm, {DateTime? at, int pick = 7}) =>
      ledger.reserve(
        alarm: alarm,
        ringAt: at ?? ringAt,
        resolveRecipient: (a) => a.donationRecipient ?? 'global@example.com',
        pickSnoozeTimeout: (_, __) => pick,
      );

  group('reserve', () {
    test('key is alarm id plus scheduled ring time, deadline is ring time '
        'plus timeout', () async {
      final o = await reserve(
        Alarm(id: 3, hour: 7, minute: 0, amountSats: 21, timeoutSeconds: 120),
      );

      expect(o!.key, '3:${ringAt.millisecondsSinceEpoch}');
      expect(o.deadline, ringAt.add(const Duration(seconds: 120)));
      expect(o.amountSats, 21);
      expect(o.recipient, 'global@example.com');
      expect(o.status, ZapObligationStatus.pending);
    });

    test('second snooze ring draws its random timeout at reservation',
        () async {
      final o = await reserve(
        Alarm(
          id: 3,
          hour: 7,
          minute: 0,
          amountSats: 21,
          timeoutSeconds: 300,
          enableSnooze: true,
          snoozeCount: 1,
          snoozeTimeoutRange: (3, 30),
        ),
        pick: 9,
      );

      expect(o!.deadline, ringAt.add(const Duration(seconds: 9)));
    });

    test('first snooze ring and alarms without payment reserve nothing',
        () async {
      expect(
        await reserve(Alarm(
          id: 1,
          hour: 7,
          minute: 0,
          amountSats: 21,
          enableSnooze: true,
          snoozeCount: 0,
        )),
        isNull,
      );
      expect(await reserve(Alarm(id: 2, hour: 7, minute: 0)), isNull);
      expect(ledger.all(), isEmpty);
    });

    test('rescheduling the same alarm cancels its earlier pending obligation',
        () async {
      final alarm =
          Alarm(id: 3, hour: 7, minute: 0, amountSats: 21, timeoutSeconds: 60);
      await reserve(alarm);
      await reserve(alarm, at: ringAt.add(const Duration(days: 1)));

      expect(ledger.pending(), hasLength(1));
      expect(ledger.pending().single.ringAt, ringAt.add(const Duration(days: 1)));
      expect(
        ledger.all().map((o) => o.status),
        unorderedEquals(
            [ZapObligationStatus.cancelled, ZapObligationStatus.pending]),
      );
    });

    test('reserving an alarm that lost its payment cancels what it owed',
        () async {
      await reserve(Alarm(id: 3, hour: 7, minute: 0, amountSats: 21));
      await reserve(Alarm(id: 3, hour: 7, minute: 0));

      expect(ledger.pending(), isEmpty);
      expect(ledger.all().single.status, ZapObligationStatus.cancelled);
    });
  });

  group('markAttempted', () {
    test('wins exactly once', () async {
      final o = await reserve(Alarm(id: 3, hour: 7, minute: 0, amountSats: 21));

      final first = ledger.markAttempted(o!.key);
      final second = ledger.markAttempted(o.key);

      expect(await first, isTrue);
      expect(await second, isFalse);
      expect(ledger.get(o.key)!.status, ZapObligationStatus.attempted);
    });

    test('does not win on a cancelled obligation', () async {
      final o = await reserve(Alarm(id: 3, hour: 7, minute: 0, amountSats: 21));
      await ledger.cancelPendingFor(3);

      expect(await ledger.markAttempted(o!.key), isFalse);
    });

    test('does not win on an unknown key', () async {
      expect(await ledger.markAttempted('9:0'), isFalse);
    });
  });

  group('pendingForRing', () {
    test('returns the latest pending obligation whose ring time has come',
        () async {
      final alarm = Alarm(id: 3, hour: 7, minute: 0, amountSats: 21);
      await reserve(alarm, at: ringAt.add(const Duration(days: 1)));

      expect(ledger.pendingForRing(3, ringAt), isNull);
      expect(
        ledger.pendingForRing(3, ringAt.add(const Duration(days: 1)))?.ringAt,
        ringAt.add(const Duration(days: 1)),
      );
    });
  });

  group('persistence', () {
    test('survives a JSON round trip with every field', () async {
      final o = await reserve(Alarm(
        id: 3,
        hour: 7,
        minute: 0,
        amountSats: 21,
        donationRecipient: 'me@example.com',
      ));
      await ledger.markAttempted(o!.key, at: ringAt);
      await ledger.markFailed(o.key, 'boom', at: ringAt);

      final reloaded =
          ZapLedger(await SharedPreferences.getInstance()).get(o.key)!;
      expect(reloaded.status, ZapObligationStatus.failed);
      expect(reloaded.attemptedAt, ringAt);
      expect(reloaded.settledAt, ringAt);
      expect(reloaded.error, 'boom');
      expect(reloaded.recipient, 'me@example.com');
    });

    test('an unreadable ledger is treated as empty, not thrown', () async {
      SharedPreferences.setMockInitialValues({ZapLedger.storageKey: '{bad'});
      final broken = ZapLedger(await SharedPreferences.getInstance());

      expect(broken.all(), isEmpty);
    });
  });
}
