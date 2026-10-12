import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/alarm.dart';
import '../models/zap_obligation.dart';

/// Persistent record of every zap an alarm may owe.
///
/// Lives in SharedPreferences next to the alarms. Status transitions are
/// written through the in-memory cache first, so a check-and-set such as
/// [markAttempted] is atomic with respect to other Dart callers.
class ZapLedger {
  ZapLedger(this._prefs);

  static const String storageKey = 'zap_obligations';

  /// Settled obligations older than this are pruned on the next write.
  static const Duration retention = Duration(days: 7);

  final SharedPreferences _prefs;

  List<ZapObligation> all() {
    final raw = _prefs.getString(storageKey);
    if (raw == null) return [];
    try {
      final decoded = json.decode(raw) as List<dynamic>;
      return decoded
          .map((e) => ZapObligation.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('⚠️ zap ledger unreadable, starting empty: $e');
      return [];
    }
  }

  ZapObligation? get(String key) {
    for (final o in all()) {
      if (o.key == key) return o;
    }
    return null;
  }

  List<ZapObligation> pending() => all().where((o) => o.isPending).toList();

  /// Pending obligation for [alarmId] whose ring time is at or before [now]
  /// (the one that is ringing or just rang), latest first.
  ZapObligation? pendingForRing(int alarmId, DateTime now) {
    final candidates = pending()
        .where((o) => o.alarmId == alarmId && !o.ringAt.isAfter(now))
        .toList()
      ..sort((a, b) => b.ringAt.compareTo(a.ringAt));
    return candidates.isEmpty ? null : candidates.first;
  }

  /// Reserves the obligation for a ring scheduled at [ringAt]. Any other
  /// pending obligation for the same alarm is cancelled, because a reschedule
  /// supersedes it. Returns null when the alarm has no payment configured or
  /// is the first ring of snooze mode, which never pays.
  ///
  /// [resolveRecipient] runs now so the destination is frozen with the
  /// obligation; [pickSnoozeTimeout] draws the second-ring random timeout
  /// here, so the deadline is a property of the scheduled ring, not of when
  /// a screen happened to appear.
  Future<ZapObligation?> reserve({
    required Alarm alarm,
    required DateTime ringAt,
    required String Function(Alarm alarm) resolveRecipient,
    required int Function(int minSeconds, int maxSeconds) pickSnoozeTimeout,
  }) async {
    final amountSats = alarm.amountSats;
    if (amountSats == null) {
      await cancelPendingFor(alarm.id);
      return null;
    }
    if (alarm.enableSnooze && alarm.snoozeCount == 0) {
      await cancelPendingFor(alarm.id);
      return null;
    }

    final timeoutSeconds = alarm.enableSnooze && alarm.snoozeCount == 1
        ? pickSnoozeTimeout(
            alarm.snoozeTimeoutRange.$1,
            alarm.snoozeTimeoutRange.$2,
          )
        : (alarm.timeoutSeconds ?? 300);

    final obligation = ZapObligation(
      alarmId: alarm.id,
      ringAt: ringAt,
      deadline: ringAt.add(Duration(seconds: timeoutSeconds)),
      amountSats: amountSats,
      recipient: resolveRecipient(alarm),
    );

    final list = all()
        .map((o) => o.alarmId == alarm.id && o.isPending
            ? o.copyWith(status: ZapObligationStatus.cancelled, settledAt: ringAt)
            : o)
        .where((o) => o.key != obligation.key)
        .toList()
      ..add(obligation);
    await _write(list);
    debugPrint('📒 reserved $obligation');
    return obligation;
  }

  /// Cancels every pending obligation for [alarmId] (alarm stopped, disabled,
  /// deleted or rescheduled).
  Future<void> cancelPendingFor(int alarmId, {DateTime? at}) async {
    final list = all();
    var changed = false;
    for (var i = 0; i < list.length; i++) {
      final o = list[i];
      if (o.alarmId == alarmId && o.isPending) {
        list[i] = o.copyWith(
          status: ZapObligationStatus.cancelled,
          settledAt: at ?? DateTime.now(),
        );
        changed = true;
      }
    }
    if (changed) await _write(list);
  }

  /// At-most-once gate. Flips [key] from pending to attempted and returns
  /// true; returns false if it was not pending, in which case the caller must
  /// not pay. The in-memory state changes before the await, so two callers
  /// in the same isolate cannot both win.
  Future<bool> markAttempted(String key, {DateTime? at}) async {
    final list = all();
    final index = list.indexWhere((o) => o.key == key);
    if (index == -1 || !list[index].isPending) return false;
    list[index] = list[index].copyWith(
      status: ZapObligationStatus.attempted,
      attemptedAt: at ?? DateTime.now(),
    );
    await _write(list);
    return true;
  }

  Future<void> markPaid(String key, String paymentHash, {DateTime? at}) =>
      _setStatus(key, ZapObligationStatus.paid, at: at, paymentHash: paymentHash);

  Future<void> markFailed(String key, Object error, {DateTime? at}) =>
      _setStatus(key, ZapObligationStatus.failed, at: at, error: '$error');

  Future<void> markUnprovable(String key, {DateTime? at}) =>
      _setStatus(key, ZapObligationStatus.unprovable, at: at);

  Future<void> markCancelled(String key, {DateTime? at}) =>
      _setStatus(key, ZapObligationStatus.cancelled, at: at);

  Future<void> _setStatus(
    String key,
    ZapObligationStatus status, {
    DateTime? at,
    String? paymentHash,
    String? error,
  }) async {
    final list = all();
    final index = list.indexWhere((o) => o.key == key);
    if (index == -1) return;
    list[index] = list[index].copyWith(
      status: status,
      settledAt: at ?? DateTime.now(),
      paymentHash: paymentHash,
      error: error,
    );
    await _write(list);
  }

  Future<void> _write(List<ZapObligation> list) async {
    final cutoff = DateTime.now().subtract(retention);
    final kept = list
        .where((o) => o.isPending || (o.settledAt ?? o.deadline).isAfter(cutoff))
        .toList();
    // shared_preferences updates its in-memory cache synchronously, so a
    // reader in the same isolate sees the new state before the disk write.
    await _prefs.setString(
      storageKey,
      json.encode(kept.map((o) => o.toJson()).toList()),
    );
  }
}
