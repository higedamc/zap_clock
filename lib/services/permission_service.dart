import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

/// Permission management service
/// Request and check various permissions required by the app
class PermissionService {
  static const _permissionChannel = MethodChannel('com.zapclock.zap_clock/permission');
  /// Request all required permissions
  /// Call after onboarding completion
  Future<Map<Permission, PermissionStatus>> requestAllPermissions() async {
    debugPrint('📋 Requesting required permissions');
    
    final results = <Permission, PermissionStatus>{};
    
    // 1. Notification permission
    try {
      final notificationStatus = await Permission.notification.request();
      results[Permission.notification] = notificationStatus;
      debugPrint('📬 Notification permission: ${notificationStatus.name}');
    } catch (e) {
      debugPrint('⚠️ Notification permission request error: $e');
    }
    
    // 2. Exact alarm permission (Android 12+)
    try {
      final alarmStatus = await Permission.scheduleExactAlarm.request();
      results[Permission.scheduleExactAlarm] = alarmStatus;
      debugPrint('⏰ Exact alarm permission: ${alarmStatus.name}');
    } catch (e) {
      debugPrint('⚠️ Alarm permission request error: $e');
    }
    
    // 3. Audio file access permission (Android 13+)
    try {
      final audioStatus = await Permission.audio.request();
      results[Permission.audio] = audioStatus;
      debugPrint('🎵 Audio file access permission: ${audioStatus.name}');
    } catch (e) {
      debugPrint('⚠️ Audio file access permission request error: $e');
    }
    
    // 4. Storage read permission (Android 12 and earlier)
    // Android 13+ uses Permission.audio
    try {
      final storageStatus = await Permission.storage.status;
      if (!storageStatus.isGranted) {
        final result = await Permission.storage.request();
        results[Permission.storage] = result;
        debugPrint('💾 Storage read permission: ${result.name}');
      }
    } catch (e) {
      debugPrint('⚠️ Storage permission request error: $e');
    }
    
    // 5. Check Full Screen Intent permission (Android 10+)
    // This cannot be requested directly, only checked
    try {
      final canUse = await canUseFullScreenIntent();
      debugPrint('🔓 Full Screen Intent permission: ${canUse ? "granted" : "not granted"}');
    } catch (e) {
      debugPrint('⚠️ Full Screen Intent check error: $e');
    }
    
    debugPrint('✅ Permission request completed');
    return results;
  }
  
  /// Check if notification permission is granted
  Future<bool> hasNotificationPermission() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }
  
  /// Check if exact alarm permission is granted
  Future<bool> hasAlarmPermission() async {
    final status = await Permission.scheduleExactAlarm.status;
    return status.isGranted;
  }
  
  /// Check if audio file access permission is granted
  Future<bool> hasAudioPermission() async {
    final status = await Permission.audio.status;
    return status.isGranted;
  }
  
  /// Check if all required permissions are granted
  Future<bool> hasAllRequiredPermissions() async {
    final notification = await hasNotificationPermission();
    final alarm = await hasAlarmPermission();
    final audio = await hasAudioPermission();
    
    return notification && alarm && audio;
  }
  
  /// Open app settings if permission is denied
  Future<void> openAppSettings() async {
    debugPrint('⚙️ Opening app settings');
    await openAppSettings();
  }
  
  /// Display permission request result summary (for debugging)
  void logPermissionSummary(Map<Permission, PermissionStatus> results) {
    debugPrint('========== Permission Request Results ==========');
    results.forEach((permission, status) {
      final emoji = status.isGranted ? '✅' : '❌';
      debugPrint('$emoji ${permission.toString()}: ${status.name}');
    });
    debugPrint('=======================================');
  }
  
  /// Check if app can use Full Screen Intent (Android 10+)
  /// This is required to show alarm screen over lock screen
  Future<bool> canUseFullScreenIntent() async {
    try {
      final result = await _permissionChannel.invokeMethod<bool>('canUseFullScreenIntent');
      return result ?? false;
    } catch (e) {
      debugPrint('⚠️ Failed to check Full Screen Intent permission: $e');
      return false;
    }
  }
  
  /// Open system settings to grant Full Screen Intent permission
  /// User needs to manually enable this in Android settings
  Future<void> openFullScreenIntentSettings() async {
    try {
      await _permissionChannel.invokeMethod('openFullScreenIntentSettings');
      debugPrint('⚙️ Opened Full Screen Intent settings');
    } catch (e) {
      debugPrint('⚠️ Failed to open Full Screen Intent settings: $e');
    }
  }
}
