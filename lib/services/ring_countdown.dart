/// Countdown from "alarm started ringing" to "auto zap". Implemented by
/// [AlarmCountdownService]; tests inject a fake and fire [onTimeout] by hand.
abstract class RingCountdown {
  Future<void> start({
    required int alarmId,
    required int timeoutSeconds,
    required Future<void> Function() onTimeout,
  });

  void stop(int alarmId);

  /// Seconds left, or null when no countdown is running for [alarmId].
  Future<int?> remainingSeconds(int alarmId);
}
