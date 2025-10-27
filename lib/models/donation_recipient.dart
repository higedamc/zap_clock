import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:yaml/yaml.dart';

/// 送金先プリセット
class DonationRecipient {
  /// 表示名
  final String name;
  
  /// Lightning Address
  final String lightningAddress;
  
  /// 説明文
  final String description;
  
  /// アイコン絵文字
  final String emoji;
  
  const DonationRecipient({
    required this.name,
    required this.lightningAddress,
    required this.description,
    required this.emoji,
  });
  
  /// JSON形式に変換
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'lightningAddress': lightningAddress,
      'description': description,
      'emoji': emoji,
    };
  }
  
  /// JSONから復元
  factory DonationRecipient.fromJson(Map<String, dynamic> json) {
    return DonationRecipient(
      name: json['name'] as String,
      lightningAddress: json['lightningAddress'] as String,
      description: json['description'] as String,
      emoji: json['emoji'] as String,
    );
  }
  
  /// YAMLから復元
  factory DonationRecipient.fromYaml(dynamic yaml) {
    return DonationRecipient(
      name: yaml['name'] as String,
      lightningAddress: yaml['lightningAddress'] as String,
      description: yaml['description'] as String,
      emoji: yaml['emoji'] as String,
    );
  }
}

/// 送金先プリセットリスト
class DonationRecipients {
  /// プリセット一覧（ロード後にセットされる）
  static List<DonationRecipient> _presets = [];
  
  /// デフォルトの送金先インデックス
  static int _defaultIndex = 0;
  
  /// ロード済みフラグ
  static bool _isLoaded = false;
  
  /// assets/donation_recipients.yamlから寄付先リストをロード
  static Future<void> loadFromAssets() async {
    if (_isLoaded) return; // 既にロード済みの場合はスキップ
    
    try {
      final yamlString = await rootBundle.loadString('assets/donation_recipients.yaml');
      final yamlData = loadYaml(yamlString);
      
      final presetsData = yamlData['presets'] as YamlList;
      _presets = presetsData
          .map((item) => DonationRecipient.fromYaml(item))
          .toList();
      
      _defaultIndex = yamlData['default_index'] as int? ?? 0;
      _isLoaded = true;
    } catch (e) {
      // フォールバック: YAMLロード失敗時はデフォルトリストを使用
      _presets = _getDefaultPresets();
      _defaultIndex = 0;
      _isLoaded = true;
      print('Warning: Failed to load donation_recipients.yaml, using default presets: $e');
    }
  }
  
  /// フォールバック用のデフォルトプリセット
  static List<DonationRecipient> _getDefaultPresets() {
    return const [
      DonationRecipient(
        name: 'ZapClock Developer (soggyhack)',
        lightningAddress: 'soggyhack118@walletofsatoshi.com',
        description: 'Creator of ZapClock alarm app',
        emoji: '⚡',
      ),
    ];
  }
  
  /// プリセット一覧を取得（未ロードの場合は自動ロード）
  static Future<List<DonationRecipient>> get presets async {
    if (!_isLoaded) {
      await loadFromAssets();
    }
    return _presets;
  }
  
  /// プリセット一覧を同期的に取得（既にロード済みの場合のみ）
  static List<DonationRecipient> get presetsSync {
    if (!_isLoaded) {
      throw StateError('DonationRecipients not loaded yet. Call loadFromAssets() first.');
    }
    return _presets;
  }
  
  /// デフォルトの送金先
  static Future<DonationRecipient> get defaultRecipient async {
    final list = await presets;
    return list[_defaultIndex];
  }
  
  /// デフォルトの送金先（同期版）
  static DonationRecipient get defaultRecipientSync {
    return presetsSync[_defaultIndex];
  }
  
  /// Lightning Addressから受取人を検索
  static Future<DonationRecipient?> findByAddress(String lightningAddress) async {
    final list = await presets;
    try {
      return list.firstWhere(
        (recipient) => recipient.lightningAddress == lightningAddress,
      );
    } catch (e) {
      return null;
    }
  }
  
  /// ロード状態をリセット（テスト用）
  static void reset() {
    _presets = [];
    _defaultIndex = 0;
    _isLoaded = false;
  }
}

