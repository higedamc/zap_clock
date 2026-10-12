import 'dart:async';

import 'package:zap_clock/models/alarm.dart';
import 'package:zap_clock/services/alarm_platform.dart';
import 'package:zap_clock/services/alarm_ring_controller.dart';
import 'package:zap_clock/services/ring_countdown.dart';
import 'package:zap_clock/services/ring_journal.dart';
import 'package:zap_clock/services/zap_executor.dart';

/// In-memory stand-in for the alarm plugin. Tests drive [ring] / [stopNative]
/// to emulate the native side.
class FakeAlarmPlatform implements AlarmPlatform {
  final _controller = StreamController<Set<int>>.broadcast();
  final Set<int> _ringing = {};
  final List<int> stopCalls = [];
  int backstopCalls = 0;
  bool serviceAlive = false;

  @override
  Stream<Set<int>> get ringingIds async* {
    yield Set.of(_ringing);
    yield* _controller.stream;
  }

  /// Native side started ringing [id].
  void ring(int id) {
    _ringing.add(id);
    serviceAlive = true;
    _controller.add(Set.of(_ringing));
  }

  /// Native side stopped [id] without any Dart call (notification Stop).
  void stopNative(int id) {
    _ringing.remove(id);
    serviceAlive = false;
    _controller.add(Set.of(_ringing));
  }

  @override
  Future<bool> stop(int alarmId) async {
    stopCalls.add(alarmId);
    final wasRinging = _ringing.remove(alarmId);
    if (wasRinging) {
      serviceAlive = false;
      _controller.add(Set.of(_ringing));
    }
    return true;
  }

  @override
  Future<bool> stopRingingBackstop() async {
    backstopCalls++;
    final stopped = serviceAlive;
    serviceAlive = false;
    return stopped;
  }

  Future<void> close() => _controller.close();
}

class FakeScheduler implements AlarmScheduler {
  final List<Alarm> scheduled = [];
  Object? error;

  @override
  Future<void> scheduleAlarm(Alarm alarm) async {
    if (error != null) throw error!;
    scheduled.add(alarm);
  }
}

class FakePayer implements LightningPayer {
  FakePayer({this.error});

  final Object? error;
  final List<({String connection, String address, int sats, String? comment})>
      payments = [];

  @override
  Future<String> pay({
    required String connectionString,
    required String lightningAddress,
    required int amountSats,
    String? comment,
  }) async {
    payments.add((
      connection: connectionString,
      address: lightningAddress,
      sats: amountSats,
      comment: comment,
    ));
    if (error != null) throw error!;
    return 'hash-${payments.length}';
  }
}

class FakeCountdown implements RingCountdown {
  final Map<int, ({int timeoutSeconds, Future<void> Function() onTimeout})>
      running = {};
  final List<int> stopCalls = [];

  @override
  Future<void> start({
    required int alarmId,
    required int timeoutSeconds,
    required Future<void> Function() onTimeout,
  }) async {
    running[alarmId] = (timeoutSeconds: timeoutSeconds, onTimeout: onTimeout);
  }

  @override
  void stop(int alarmId) {
    stopCalls.add(alarmId);
    running.remove(alarmId);
  }

  @override
  Future<int?> remainingSeconds(int alarmId) async =>
      running[alarmId]?.timeoutSeconds;

  /// Fires the countdown the way the real Timer would.
  Future<void> expire(int alarmId) async {
    final entry = running.remove(alarmId);
    if (entry == null) throw StateError('no countdown for $alarmId');
    await entry.onTimeout();
  }
}

class FakeJournal implements RingJournal {
  final List<RingJournalEntry> entries = [];

  /// When set, [read] throws it instead of returning entries.
  Object? readError;

  void start(DateTime at) => entries.add(RingJournalEntry(isStart: true, at: at));
  void stop(DateTime at) => entries.add(RingJournalEntry(isStart: false, at: at));

  @override
  Future<List<RingJournalEntry>> read() async {
    final error = readError;
    if (error != null) throw error;
    return List.of(entries);
  }
}

/// A payer that records what the ledger looked like at the moment it was
/// called, so tests can prove `attempted` is written before the wallet call.
class LedgerPeekingPayer extends FakePayer {
  LedgerPeekingPayer(this.peek, {super.error});

  final String? Function() peek;
  final List<String?> statusesSeen = [];

  @override
  Future<String> pay({
    required String connectionString,
    required String lightningAddress,
    required int amountSats,
    String? comment,
  }) {
    statusesSeen.add(peek());
    return super.pay(
      connectionString: connectionString,
      lightningAddress: lightningAddress,
      amountSats: amountSats,
      comment: comment,
    );
  }
}
