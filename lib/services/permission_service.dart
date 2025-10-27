import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// 権限管理サービス
/// アプリに必要な各種権限のリクエストとチェックを行う
class PermissionService {
  /// 必要な権限を全てリクエスト
  /// オンボーディング完了後に呼び出す
  Future<Map<Permission, PermissionStatus>> requestAllPermissions() async {
    debugPrint('📋 アプリに必要な権限をリクエスト開始');
    
    final results = <Permission, PermissionStatus>{};
    
    // 1. 通知権限
    try {
      final notificationStatus = await Permission.notification.request();
      results[Permission.notification] = notificationStatus;
      debugPrint('📬 通知権限: ${notificationStatus.name}');
    } catch (e) {
      debugPrint('⚠️ 通知権限リクエストエラー: $e');
    }
    
    // 2. 正確なアラーム権限 (Android 12以降)
    try {
      final alarmStatus = await Permission.scheduleExactAlarm.request();
      results[Permission.scheduleExactAlarm] = alarmStatus;
      debugPrint('⏰ 正確なアラーム権限: ${alarmStatus.name}');
    } catch (e) {
      debugPrint('⚠️ アラーム権限リクエストエラー: $e');
    }
    
    // 3. 音楽ファイルアクセス権限 (Android 13以降)
    try {
      final audioStatus = await Permission.audio.request();
      results[Permission.audio] = audioStatus;
      debugPrint('🎵 音楽ファイルアクセス権限: ${audioStatus.name}');
    } catch (e) {
      debugPrint('⚠️ 音楽ファイルアクセス権限リクエストエラー: $e');
    }
    
    // 4. ストレージ読み取り権限 (Android 12以前)
    // Android 13以降はPermission.audioで対応
    try {
      final storageStatus = await Permission.storage.status;
      if (!storageStatus.isGranted) {
        final result = await Permission.storage.request();
        results[Permission.storage] = result;
        debugPrint('💾 ストレージ読み取り権限: ${result.name}');
      }
    } catch (e) {
      debugPrint('⚠️ ストレージ権限リクエストエラー: $e');
    }
    
    debugPrint('✅ 権限リクエスト完了');
    return results;
  }
  
  /// 通知権限がgrantedかチェック
  Future<bool> hasNotificationPermission() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }
  
  /// 正確なアラーム権限がgrantedかチェック
  Future<bool> hasAlarmPermission() async {
    final status = await Permission.scheduleExactAlarm.status;
    return status.isGranted;
  }
  
  /// 音楽ファイルアクセス権限がgrantedかチェック
  Future<bool> hasAudioPermission() async {
    final status = await Permission.audio.status;
    return status.isGranted;
  }
  
  /// 必要な権限が全て付与されているかチェック
  Future<bool> hasAllRequiredPermissions() async {
    final notification = await hasNotificationPermission();
    final alarm = await hasAlarmPermission();
    final audio = await hasAudioPermission();
    
    return notification && alarm && audio;
  }
  
  /// 権限が拒否されている場合、設定画面を開く
  Future<void> openAppSettings() async {
    debugPrint('⚙️ アプリ設定画面を開く');
    await openAppSettings();
  }
  
  /// 権限リクエスト結果のサマリーを表示（デバッグ用）
  void logPermissionSummary(Map<Permission, PermissionStatus> results) {
    debugPrint('========== 権限リクエスト結果 ==========');
    results.forEach((permission, status) {
      final emoji = status.isGranted ? '✅' : '❌';
      debugPrint('$emoji ${permission.toString()}: ${status.name}');
    });
    debugPrint('=======================================');
  }
}

