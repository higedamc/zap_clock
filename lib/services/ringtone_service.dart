import 'package:flutter/services.dart';

/// システムアラーム音源を選択するサービス
class RingtoneService {
  static const _channel = MethodChannel('com.zapclock.zap_clock/ringtone');
  
  /// システムアラーム音源ピッカーを開く
  /// 
  /// 戻り値：
  /// - null: キャンセルされた場合
  /// - Map: 音源が選択された場合
  ///   - uri: システムのURI文字列
  ///   - path: ローカルにコピーされたファイルパス（alarmパッケージで使用）
  ///   - name: 音源の表示名
  Future<Map<String, String>?> pickRingtone() async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('pickRingtone');
      
      if (result == null) {
        return null;
      }
      
      // dynamic MapをString Mapに変換
      return {
        'uri': result['uri'] as String,
        'path': result['path'] as String,
        'name': result['name'] as String,
      };
    } on PlatformException catch (e) {
      throw Exception('音源の選択に失敗しました: ${e.message}');
    }
  }
  
  /// URIから音源名を取得
  Future<String> getRingtoneName(String uri) async {
    try {
      final name = await _channel.invokeMethod<String>(
        'getRingtoneName',
        {'uri': uri},
      );
      return name ?? 'Unknown';
    } on PlatformException catch (e) {
      throw Exception('音源名の取得に失敗しました: ${e.message}');
    }
  }
}

