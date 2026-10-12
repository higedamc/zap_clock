import '../models/zap_obligation.dart';
import 'ring_journal.dart';

/// What to do with a pending obligation right now.
enum SettlementDecision {
  /// Ring time or deadline is still ahead; nothing to do yet.
  wait,

  /// The alarm rang through its deadline: pay.
  pay,

  /// The alarm was stopped before its deadline: nothing is owed.
  cancel,

  /// The deadline passed but there is no record that the alarm rang through
  /// it (process killed, device off, journal lost). Do not pay.
  unprovable,
}

/// Pure settlement rule. Used for obligations whose deadline passed while the
/// Dart engine was not there to see it. The live case (engine up, countdown
/// fires) never comes here; AlarmRingController pays directly.
///
/// Rules, in order:
/// 1. Before the deadline: wait.
/// 2. If the platform reports the alarm as ringing right now, it rang through
///    the deadline: pay.
/// 3. Otherwise look at the native journal for the ring window that belongs
///    to this obligation: the first start at or after `ringAt - startSlack`
///    **and before the deadline**, and the first stop after that start.
///    - stop at or after the deadline: pay.
///    - stop before the deadline: cancel.
///    - start without a stop, or no start at all: unprovable.
///
/// The upper bound matters for money: a ring that started after the deadline
/// cannot have rung through it. Without the bound, an obligation whose ring
/// never happened (device off, exact alarm dropped) would be settled by the
/// next unrelated ring, whose stop is far past the stale deadline, and pay.
///
/// The journal carries no alarm id (AlarmRingingLiveData is a bare Boolean
/// and only one alarm rings at a time), so the window is matched by time.
SettlementDecision decideSettlement(
  ZapObligation obligation, {
  required DateTime now,
  required bool ringingNow,
  required List<RingJournalEntry> journal,
  Duration startSlack = const Duration(seconds: 30),
}) {
  if (!obligation.isPending) return SettlementDecision.wait;
  if (now.isBefore(obligation.deadline)) return SettlementDecision.wait;
  if (ringingNow) return SettlementDecision.pay;

  final sorted = [...journal]..sort((a, b) => a.at.compareTo(b.at));
  final earliestStart = obligation.ringAt.subtract(startSlack);

  RingJournalEntry? start;
  for (final entry in sorted) {
    if (entry.isStart &&
        !entry.at.isBefore(earliestStart) &&
        entry.at.isBefore(obligation.deadline)) {
      start = entry;
      break;
    }
  }
  if (start == null) return SettlementDecision.unprovable;

  RingJournalEntry? stop;
  for (final entry in sorted) {
    if (!entry.isStart && entry.at.isAfter(start.at)) {
      stop = entry;
      break;
    }
  }
  if (stop == null) return SettlementDecision.unprovable;

  return stop.at.isBefore(obligation.deadline)
      ? SettlementDecision.cancel
      : SettlementDecision.pay;
}
