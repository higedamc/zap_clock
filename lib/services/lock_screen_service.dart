import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Decides where the user lands when the ring screen is dismissed.
///
/// The lock-screen bypass itself is not controlled here. The `alarm` plugin
/// sets showWhenLocked / turnScreenOn while an alarm is ringing and clears them
/// when it stops (AlarmPlugin.kt, driven by AlarmRingingLiveData). This service
/// only asks the platform to hide the task when the keyguard is still locked,
/// so stopping an alarm from the lock screen returns to the lock screen instead
/// of exposing the alarm list (issue #12).
class LockScreenService {
  static const _channel = MethodChannel('com.zapclock.zap_clock/lockscreen');

  /// Returns true when the task was moved to the background because the
  /// device is still locked. Returns false when the device is unlocked or the
  /// platform has no native implementation; callers navigate normally then.
  static Future<bool> leaveRingScreen() async {
    try {
      final moved = await _channel.invokeMethod<bool>('leaveRingScreen');
      debugPrint('🔒 leaveRingScreen: movedToBack=$moved');
      return moved ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException catch (e) {
      debugPrint('⚠️ leaveRingScreen failed: $e');
      return false;
    }
  }
}
