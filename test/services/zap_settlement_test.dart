import 'package:flutter_test/flutter_test.dart';
import 'package:zap_clock/models/zap_obligation.dart';
import 'package:zap_clock/services/ring_journal.dart';
import 'package:zap_clock/services/zap_settlement.dart';

void main() {
  final ringAt = DateTime(2026, 10, 14, 6, 0);
  final deadline = ringAt.add(const Duration(seconds: 90));
  final later = deadline.add(const Duration(hours: 1));

  final pending = ZapObligation(
    alarmId: 1,
    ringAt: ringAt,
    deadline: deadline,
    amountSats: 21,
    recipient: 'r@example.com',
  );

  RingJournalEntry start(DateTime at) => RingJournalEntry(isStart: true, at: at);
  RingJournalEntry stop(DateTime at) => RingJournalEntry(isStart: false, at: at);

  SettlementDecision decide({
    ZapObligation? obligation,
    DateTime? now,
    bool ringingNow = false,
    List<RingJournalEntry> journal = const [],
  }) =>
      decideSettlement(
        obligation ?? pending,
        now: now ?? later,
        ringingNow: ringingNow,
        journal: journal,
      );

  test('before the deadline: wait', () {
    expect(
      decide(now: ringAt.add(const Duration(seconds: 10))),
      SettlementDecision.wait,
    );
  });

  test('not pending: wait regardless of the journal', () {
    expect(
      decide(
        obligation: pending.copyWith(status: ZapObligationStatus.paid),
        journal: [start(ringAt), stop(later)],
      ),
      SettlementDecision.wait,
    );
  });

  test('still ringing past the deadline: pay', () {
    expect(decide(ringingNow: true), SettlementDecision.pay);
  });

  test('stopped after the deadline: pay', () {
    expect(
      decide(journal: [start(ringAt), stop(deadline.add(const Duration(seconds: 1)))]),
      SettlementDecision.pay,
    );
  });

  test('stopped exactly at the deadline: pay', () {
    expect(
      decide(journal: [start(ringAt), stop(deadline)]),
      SettlementDecision.pay,
    );
  });

  test('stopped before the deadline: cancel', () {
    expect(
      decide(journal: [start(ringAt), stop(ringAt.add(const Duration(seconds: 30)))]),
      SettlementDecision.cancel,
    );
  });

  test('empty journal: unprovable', () {
    expect(decide(), SettlementDecision.unprovable);
  });

  test('start without a stop (process killed): unprovable', () {
    expect(decide(journal: [start(ringAt)]), SettlementDecision.unprovable);
  });

  test('a stop from an earlier ring does not count', () {
    final earlier = ringAt.subtract(const Duration(days: 1));
    expect(
      decide(journal: [
        start(earlier),
        stop(earlier.add(const Duration(minutes: 5))),
        start(ringAt),
      ]),
      SettlementDecision.unprovable,
    );
  });

  test('a start a few seconds early still belongs to this ring', () {
    expect(
      decide(journal: [
        start(ringAt.subtract(const Duration(seconds: 5))),
        stop(later),
      ]),
      SettlementDecision.pay,
    );
  });

  test('a start long before the ring time belongs to another ring', () {
    expect(
      decide(journal: [
        start(ringAt.subtract(const Duration(minutes: 10))),
        stop(later),
      ]),
      SettlementDecision.unprovable,
    );
  });

  test('journal order does not matter', () {
    expect(
      decide(journal: [stop(later), start(ringAt)]),
      SettlementDecision.pay,
    );
  });
}
