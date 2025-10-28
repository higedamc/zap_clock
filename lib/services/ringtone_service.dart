import 'package:flutter/services.dart';

/// Service for selecting system alarm sounds
class RingtoneService {
  static const _channel = MethodChannel('com.zapclock.zap_clock/ringtone');
  
  /// Open system alarm sound picker
  /// 
  /// Return value:
  /// - null: Canceled
  /// - Map: Sound selected
  ///   - uri: System URI string
  ///   - path: Local copied file path (used by alarm package)
  ///   - name: Sound display name
  Future<Map<String, String>?> pickRingtone() async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('pickRingtone');
      
      if (result == null) {
        return null;
      }
      
      // Convert dynamic Map to String Map
      return {
        'uri': result['uri'] as String,
        'path': result['path'] as String,
        'name': result['name'] as String,
      };
    } on PlatformException catch (e) {
      throw Exception('Failed to select sound: ${e.message}');
    }
  }
  
  /// Get sound name from URI
  Future<String> getRingtoneName(String uri) async {
    try {
      final name = await _channel.invokeMethod<String>(
        'getRingtoneName',
        {'uri': uri},
      );
      return name ?? 'Unknown';
    } on PlatformException catch (e) {
      throw Exception('Failed to get sound name: ${e.message}');
    }
  }
}
