import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/alarm.dart';
import 'alarm_platform.dart';
import 'ring_countdown.dart';
import 'storage_service.dart';
import 'zap_executor.dart';

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
class AlarmRingController {
  AlarmRingController({
    required AlarmPlatform platform,
    required StorageService storage,
    required AlarmScheduler scheduler,
    required ZapExecutor zap,
    required RingCountdown countdown,
    this.onAlarmsChanged,
    int Function(int minSeconds, int maxSeconds)? pickSnoozeTimeout,
  })  : _platform = platform,
        _storage = storage,
        _scheduler = scheduler,
        _zap = zap,
        _countdown = countdown,
        _pickSnoozeTimeout = pickSnoozeTimeout ?? _randomInclusive;

  final AlarmPlatform _platform;
  final StorageService _storage;
  final AlarmScheduler _scheduler;
  final ZapExecutor _zap;
  final RingCountdown _countdown;
  final int Function(int minSeconds, int maxSeconds) _pickSnoozeTimeout;

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
    final alarm = _findAlarm(alarmId);
    if (alarm != null) {
      outcome = await _zap.execute(alarm);
    } else {
      debugPrint('⚠️ alarm $alarmId: not found in storage, no zap');
    }

    await _silence(alarmId);
    await _finalize(alarmId, StopReason.timeout, zap: outcome);
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
  }

  Future<void> _onRingStarted(int alarmId) async {
    _ringing.add(alarmId);
    debugPrint('🚨 alarm $alarmId: ringing');

    final alarm = _findAlarm(alarmId);
    if (alarm == null) {
      debugPrint('⚠️ alarm $alarmId: not found in storage, no countdown');
    } else if (alarm.amountSats == null) {
      debugPrint('⏱️ alarm $alarmId: no payment configured, no countdown');
    } else if (alarm.enableSnooze && alarm.snoozeCount == 0) {
      debugPrint('😴 alarm $alarmId: first ring of snooze mode, waiting for Snooze');
    } else {
      final timeoutSeconds = alarm.enableSnooze && alarm.snoozeCount == 1
          ? _pickSnoozeTimeout(
              alarm.snoozeTimeoutRange.$1,
              alarm.snoozeTimeoutRange.$2,
            )
          : (alarm.timeoutSeconds ?? 300);
      await _countdown.start(
        alarmId: alarmId,
        timeoutSeconds: timeoutSeconds,
        onTimeout: () => timeoutReached(alarmId),
      );
    }

    _started.add(alarmId);
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

  static int _randomInclusive(int minSeconds, int maxSeconds) {
    if (maxSeconds <= minSeconds) return minSeconds;
    return minSeconds + Random().nextInt(maxSeconds - minSeconds + 1);
  }
}
