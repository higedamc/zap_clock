import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/alarm.dart';
import '../models/zap_obligation.dart';
import 'alarm_platform.dart';
import 'ring_countdown.dart';
import 'ring_journal.dart';
import 'ring_schedule.dart';
import 'storage_service.dart';
import 'zap_executor.dart';
import 'zap_ledger.dart';
import 'zap_settlement.dart';

/// Why a ring ended.
enum StopReason {
  /// The user pressed Stop on the ring screen.
  user,

  /// The user pressed Snooze; a second ring has been scheduled.
  snooze,

  /// The countdown expired; the zap was attempted first.
  timeout,

  /// The platform stopped the alarm outside the app (notification Stop
  /// button, notification swiped away, service destroyed).
  external,
}

/// Published once per ring when it has been fully torn down.
class RingEnded {
  const RingEnded({required this.alarmId, required this.reason, this.zap});

  final int alarmId;
  final StopReason reason;
  final ZapOutcome? zap;
}

/// What the controller needs from [AlarmService].
abstract class AlarmScheduler {
  Future<void> scheduleAlarm(Alarm alarm);
}

/// The single stop path for a ringing alarm.
///
/// Every way a ring can end (Stop button, Snooze, countdown timeout, stop from
/// the notification) converges on [_finalize], which cancels the countdown,
/// resets `snoozeCount`, reschedules repeating alarms and publishes
/// [ringEnded]. Sound, vibration and the foreground notification are stopped
/// through [AlarmPlatform.stop] followed by [AlarmPlatform.stopRingingBackstop],
/// so a stop never depends on the plugin's view of which alarm is ringing.
///
/// The native ringing set ([AlarmPlatform.ringingIds]) is the only authority
/// for "ringing". The controller mirrors it in [_ringing] and derives ring
/// start (countdown + navigation) and external stops from its changes.
///
/// Money: the zap a ring may owe is a [ZapObligation] reserved in the
/// [ZapLedger] when the ring is scheduled, with its deadline fixed there. On
/// ring start the countdown runs to that deadline. When it fires the ledger
/// entry is marked `attempted` *before* the wallet is contacted, so no
/// obligation can ever be paid twice, and a failure is never retried. A
/// deadline that passes while the engine is not running is settled by
/// [settleOverdue] from the native ring journal: stopped after the deadline
/// pays, stopped before does not, no record does not.
class AlarmRingController {
  AlarmRingController({
    required AlarmPlatform platform,
    required StorageService storage,
    required AlarmScheduler scheduler,
    required ZapExecutor zap,
    required ZapLedger ledger,
    required RingJournal journal,
    required RingCountdown countdown,
    this.onAlarmsChanged,
    int Function(int minSeconds, int maxSeconds)? pickSnoozeTimeout,
    DateTime Function()? clock,
  })  : _platform = platform,
        _storage = storage,
        _scheduler = scheduler,
        _zap = zap,
        _ledger = ledger,
        _journal = journal,
        _countdown = countdown,
        _pickSnoozeTimeout = pickSnoozeTimeout ?? defaultSnoozeTimeoutPicker,
        _clock = clock ?? DateTime.now;

  /// A ring is matched to an obligation whose ringAt is at most this far in
  /// the future, to absorb an alarm firing a few seconds early.
  static const Duration ringSlack = Duration(seconds: 60);

  final AlarmPlatform _platform;
  final StorageService _storage;
  final AlarmScheduler _scheduler;
  final ZapExecutor _zap;
  final ZapLedger _ledger;
  final RingJournal _journal;
  final RingCountdown _countdown;
  final int Function(int minSeconds, int maxSeconds) _pickSnoozeTimeout;
  final DateTime Function() _clock;
  bool _settling = false;

  /// Called after alarm data changed so the list can reload.
  final void Function()? onAlarmsChanged;

  final _started = StreamController<int>.broadcast();
  final _ended = StreamController<RingEnded>.broadcast();
  final Set<int> _ringing = {};
  final Set<int> _finalizing = {};
  StreamSubscription<Set<int>>? _subscription;

  /// Emits the alarm id when the platform starts ringing it.
  Stream<int> get ringStarted => _started.stream;

  /// Emits once per ring after everything has been torn down.
  Stream<RingEnded> get ringEnded => _ended.stream;

  Set<int> get ringingIds => Set.unmodifiable(_ringing);

  /// Seconds until the auto zap for [alarmId], or null when no countdown runs.
  Future<int?> remainingSeconds(int alarmId) =>
      _countdown.remainingSeconds(alarmId);

  /// Starts mirroring the platform's ringing set. Idempotent.
  void bind() {
    _subscription ??= _platform.ringingIds.listen(_onPlatformRinging);
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    await _started.close();
    await _ended.close();
  }

  /// Stop pressed on the ring screen.
  Future<void> stop(int alarmId) => _stopWith(alarmId, StopReason.user);

  /// Snooze pressed on the first ring of a snooze-mode alarm.
  Future<void> snooze(int alarmId) async {
    if (!_ringing.contains(alarmId)) {
      debugPrint('😴 alarm $alarmId: snooze after ring ended, ignoring');
      return;
    }
    if (!_finalizing.add(alarmId)) return;
    debugPrint('😴 alarm $alarmId: snooze');
    await _silence(alarmId);

    try {
      await _ledger.cancelPendingFor(alarmId, at: _clock());
      final alarm = _findAlarm(alarmId);
      if (alarm != null) {
        final snoozed = alarm.copyWith(snoozeCount: 1);
        await _storage.updateAlarm(snoozed);
        await _scheduler.scheduleAlarm(snoozed);
      } else {
        debugPrint('⚠️ alarm $alarmId: not found in storage, cannot snooze');
      }
    } catch (e) {
      // Never leave the id stuck in _finalizing: a later Stop must still work.
      debugPrint('⚠️ alarm $alarmId: snooze reschedule failed: $e');
    }

    _ringing.remove(alarmId);
    _finalizing.remove(alarmId);
    onAlarmsChanged?.call();
    _ended.add(RingEnded(alarmId: alarmId, reason: StopReason.snooze));
  }

  /// The countdown for [alarmId] expired. Attempts the zap exactly once, then
  /// stops the alarm whatever the outcome.
  Future<void> timeoutReached(int alarmId) async {
    if (!_ringing.contains(alarmId)) {
      debugPrint('⏰ alarm $alarmId: timeout after ring ended, ignoring');
      return;
    }
    if (!_finalizing.add(alarmId)) return;
    debugPrint('⏰ alarm $alarmId: timeout reached, executing zap');

    ZapOutcome? outcome;
    final obligation = _ledger.pendingForRing(alarmId, _clock().add(ringSlack));
    if (obligation != null) {
      outcome = await _settle(obligation);
    } else {
      debugPrint('⚠️ alarm $alarmId: no pending obligation, nothing to pay');
    }

    await _silence(alarmId);
    await _finalize(alarmId, StopReason.timeout, zap: outcome);
  }

  /// Settles obligations whose deadline passed while the engine was not there
  /// to see it (process killed, alarm handled from the notification). Safe to
  /// call often; it is a no-op when nothing is overdue.
  ///
  /// Never throws: both call sites (platform ringing events and app resume)
  /// are fire-and-forget, and an unhandled async error there would silently
  /// end catch-up for the rest of the process. One obligation failing does
  /// not stop the others from being looked at.
  Future<void> settleOverdue() async {
    if (_settling) return;
    _settling = true;
    try {
      await _settleOverdueUnguarded();
    } catch (e, st) {
      debugPrint('⚠️ settleOverdue failed: $e\n$st');
    } finally {
      _settling = false;
    }
  }

  Future<void> _settleOverdueUnguarded() async {
    final now = _clock();
    final overdue =
        _ledger.pending().where((o) => !now.isBefore(o.deadline)).toList();
    if (overdue.isEmpty) return;

    final journal = await _journal.read();
    for (final stale in overdue) {
      try {
        await _settleOne(stale, now: now, journal: journal);
      } catch (e, st) {
        debugPrint('⚠️ settle ${stale.key} failed: $e\n$st');
      }
    }
  }

  Future<void> _settleOne(
    ZapObligation stale, {
    required DateTime now,
    required List<RingJournalEntry> journal,
  }) async {
    // Re-read: a timeout or stop may have handled it while we awaited.
    final obligation = _ledger.get(stale.key);
    if (obligation == null || !obligation.isPending) return;

    final ringingNow = _ringing.contains(obligation.alarmId);
    final decision = decideSettlement(
      obligation,
      now: now,
      ringingNow: ringingNow,
      journal: journal,
    );
    debugPrint('📒 settle ${obligation.key}: $decision '
        '(ringingNow=$ringingNow, journal=${journal.length} entries)');

    switch (decision) {
      case SettlementDecision.wait:
        break;
      case SettlementDecision.pay:
        if (ringingNow) {
          // Still ringing past its deadline: the normal timeout path pays
          // and stops it.
          await timeoutReached(obligation.alarmId);
        } else {
          await _settle(obligation);
        }
      case SettlementDecision.cancel:
        await _ledger.markCancelled(obligation.key, at: now);
      case SettlementDecision.unprovable:
        await _ledger.markUnprovable(obligation.key, at: now);
        debugPrint('⚠️ ${obligation.key}: deadline passed with no proof '
            'the alarm rang through it; not paying');
    }
  }

  /// At-most-once payment of one obligation. The ledger flips to `attempted`
  /// before the wallet is contacted; if that flip loses (already attempted,
  /// cancelled, or paid), nothing is sent.
  Future<ZapOutcome> _settle(ZapObligation obligation) async {
    final now = _clock();
    final won = await _ledger.markAttempted(obligation.key, at: now);
    if (!won) {
      debugPrint('📒 ${obligation.key}: already settled, not paying again');
      return const ZapOutcome.skipped('obligation already settled');
    }

    final outcome = await _zap.execute(
      amountSats: obligation.amountSats,
      recipient: obligation.recipient,
      label: 'alarm ${obligation.alarmId}',
    );
    if (outcome.paid) {
      await _ledger.markPaid(obligation.key, outcome.paymentHash!, at: now);
    } else {
      // Skipped (no wallet configured) counts as failed: the attempt slot is
      // used up and nothing retries it.
      await _ledger.markFailed(
        obligation.key,
        outcome.error ?? outcome.skippedReason ?? 'unknown',
        at: now,
      );
    }
    return outcome;
  }

  Future<void> _stopWith(int alarmId, StopReason reason) async {
    if (!_ringing.contains(alarmId)) {
      debugPrint('🛑 alarm $alarmId: stop after ring ended, ignoring');
      return;
    }
    if (!_finalizing.add(alarmId)) return;
    debugPrint('🛑 alarm $alarmId: stop ($reason)');
    await _silence(alarmId);
    await _finalize(alarmId, reason);
  }

  void _onPlatformRinging(Set<int> ids) {
    for (final id in ids.difference(_ringing)) {
      _onRingStarted(id);
    }
    for (final id in _ringing.difference(ids).toList()) {
      if (_finalizing.contains(id)) {
        // A stop initiated here is in progress and owns the cleanup.
        continue;
      }
      debugPrint('🔕 alarm $id: stopped outside the app');
      _finalizing.add(id);
      _finalize(id, StopReason.external);
    }
    // Every platform event is also a chance to catch up on deadlines the
    // engine missed (first event after a cold start in particular).
    settleOverdue();
  }

  Future<void> _onRingStarted(int alarmId) async {
    _ringing.add(alarmId);
    final now = _clock();
    debugPrint('🚨 alarm $alarmId: ringing');

    var obligation = _ledger.pendingForRing(alarmId, now.add(ringSlack));
    if (obligation == null) {
      // Rings scheduled before the ledger existed have no reservation. Make
      // one now so the timeout still pays; the deadline counts from now.
      final alarm = _findAlarm(alarmId);
      if (alarm != null && alarm.amountSats != null) {
        debugPrint('📒 alarm $alarmId: no reservation, reserving at ring time');
        obligation = await _ledger.reserve(
          alarm: alarm,
          ringAt: now,
          resolveRecipient: _zap.resolveRecipient,
          pickSnoozeTimeout: _pickSnoozeTimeout,
        );
      }
    }

    var overdue = false;
    if (obligation == null) {
      debugPrint('⏱️ alarm $alarmId: nothing to pay, no countdown');
    } else {
      final remaining = obligation.deadline.difference(now).inSeconds;
      if (remaining <= 0) {
        // Engine came up after the deadline while the alarm is still ringing.
        overdue = true;
      } else {
        await _countdown.start(
          alarmId: alarmId,
          timeoutSeconds: remaining,
          onTimeout: () => timeoutReached(alarmId),
        );
      }
    }

    _started.add(alarmId);
    if (overdue) {
      debugPrint('⏰ alarm $alarmId: deadline already passed, paying now');
      await timeoutReached(alarmId);
    }
  }

  /// Stops sound, vibration and the foreground notification.
  Future<void> _silence(int alarmId) async {
    _countdown.stop(alarmId);
    try {
      await _platform.stop(alarmId);
    } catch (e) {
      debugPrint('⚠️ alarm $alarmId: platform stop failed: $e');
    }
    // AlarmApiImpl.stopAlarm only stops the service when the id is in
    // ringingAlarmIds (ids with a playing MediaPlayer). If audio never started
    // the service keeps vibrating and no plugin call reaches it, so the
    // backstop stops the service and the vibrator directly.
    try {
      await _platform.stopRingingBackstop();
    } catch (e) {
      debugPrint('⚠️ alarm $alarmId: native backstop failed: $e');
    }
  }

  /// Idempotent per ring: `_finalizing` must contain [alarmId] on entry.
  Future<void> _finalize(
    int alarmId,
    StopReason reason, {
    ZapOutcome? zap,
  }) async {
    _countdown.stop(alarmId);

    try {
      // Stopped before the deadline: the ring owes nothing. After a timeout
      // the obligation is already settled and this is a no-op.
      await _ledger.cancelPendingFor(alarmId, at: _clock());
      final alarm = _findAlarm(alarmId);
      if (alarm != null) {
        // Issue #13: without this reset a repeating snooze-mode alarm was
        // rescheduled with snoozeCount == 1 and rang again timeoutSeconds
        // later instead of on the next selected day.
        final reset =
            alarm.snoozeCount == 0 ? alarm : alarm.copyWith(snoozeCount: 0);
        if (!identical(reset, alarm)) {
          await _storage.updateAlarm(reset);
        }
        if (reset.hasRepeat && reset.isEnabled) {
          debugPrint('🔄 alarm $alarmId: repeating, scheduling next ring');
          await _scheduler.scheduleAlarm(reset);
        }
      }
    } catch (e) {
      // Never leave the id stuck in _finalizing: a later Stop must still work
      // and the ring screen must still be told the ring ended.
      debugPrint('⚠️ alarm $alarmId: post-ring reschedule failed: $e');
    }

    _ringing.remove(alarmId);
    _finalizing.remove(alarmId);
    onAlarmsChanged?.call();
    debugPrint('✅ alarm $alarmId: ring ended ($reason, zap=$zap)');
    _ended.add(RingEnded(alarmId: alarmId, reason: reason, zap: zap));
  }

  Alarm? _findAlarm(int alarmId) {
    for (final alarm in _storage.getAlarms()) {
      if (alarm.id == alarmId) return alarm;
    }
    return null;
  }
}
