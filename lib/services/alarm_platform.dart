import 'package:alarm/alarm.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Seam over the `alarm` plugin so [AlarmRingController] can be unit tested.
///
/// The native ringing state is the single authority for "an alarm is
/// ringing". Everything the app derives from it (ring screen, countdown,
/// lock-screen bypass) is driven through [ringingIds].
abstract class AlarmPlatform {
  /// Ids the platform currently reports as ringing. New listeners receive the
  /// current set immediately.
  Stream<Set<int>> get ringingIds;

  /// Stops the ringing alarm (or cancels its schedule). Returns the plugin's
  /// success flag.
  Future<bool> stop(int alarmId);

  /// Stops the native alarm service and the vibrator directly, regardless of
  /// what the plugin believes is ringing. Returns true when the native service
  /// was alive and has been asked to stop.
  Future<bool> stopRingingBackstop();
}

/// Production implementation backed by `package:alarm` and the
/// `com.zapclock.zap_clock/alarm_native` method channel in MainActivity.
class PluginAlarmPlatform implements AlarmPlatform {
  static const _channel = MethodChannel('com.zapclock.zap_clock/alarm_native');

  @override
  Stream<Set<int>> get ringingIds =>
      Alarm.ringing.map((set) => set.alarms.map((a) => a.id).toSet());

  @override
  Future<bool> stop(int alarmId) => Alarm.stop(alarmId);

  @override
  Future<bool> stopRingingBackstop() async {
    try {
      final stopped =
          await _channel.invokeMethod<bool>('stopRingingBackstop') ?? false;
      debugPrint('🛑 stopRingingBackstop: serviceStopped=$stopped');
      return stopped;
    } on MissingPluginException {
      return false;
    } on PlatformException catch (e) {
      debugPrint('⚠️ stopRingingBackstop failed: $e');
      return false;
    }
  }
}
