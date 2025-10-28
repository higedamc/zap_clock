import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:yaml/yaml.dart';

/// Donation recipient preset
class DonationRecipient {
  /// Display name
  final String name;
  
  /// Lightning Address
  final String lightningAddress;
  
  /// Description
  final String description;
  
  /// Icon emoji
  final String emoji;
  
  const DonationRecipient({
    required this.name,
    required this.lightningAddress,
    required this.description,
    required this.emoji,
  });
  
  /// Convert to JSON format
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'lightningAddress': lightningAddress,
      'description': description,
      'emoji': emoji,
    };
  }
  
  /// Restore from JSON
  factory DonationRecipient.fromJson(Map<String, dynamic> json) {
    return DonationRecipient(
      name: json['name'] as String,
      lightningAddress: json['lightningAddress'] as String,
      description: json['description'] as String,
      emoji: json['emoji'] as String,
    );
  }
  
  /// Restore from YAML
  factory DonationRecipient.fromYaml(dynamic yaml) {
    return DonationRecipient(
      name: yaml['name'] as String,
      lightningAddress: yaml['lightningAddress'] as String,
      description: yaml['description'] as String,
      emoji: yaml['emoji'] as String,
    );
  }
}

/// Donation recipient preset list
class DonationRecipients {
  /// Preset list (set after loading)
  static List<DonationRecipient> _presets = [];
  
  /// Default donation recipient index
  static int _defaultIndex = 0;
  
  /// Loaded flag
  static bool _isLoaded = false;
  
  /// Load donation recipient list from assets/donation_recipients.yaml
  static Future<void> loadFromAssets() async {
    if (_isLoaded) return; // Skip if already loaded
    
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
      // Fallback: Use default list if YAML loading fails
      _presets = _getDefaultPresets();
      _defaultIndex = 0;
      _isLoaded = true;
      print('Warning: Failed to load donation_recipients.yaml, using default presets: $e');
    }
  }
  
  /// Default preset for fallback
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
  
  /// Get preset list (auto-load if not loaded)
  static Future<List<DonationRecipient>> get presets async {
    if (!_isLoaded) {
      await loadFromAssets();
    }
    return _presets;
  }
  
  /// Get preset list synchronously (only if already loaded)
  static List<DonationRecipient> get presetsSync {
    if (!_isLoaded) {
      throw StateError('DonationRecipients not loaded yet. Call loadFromAssets() first.');
    }
    return _presets;
  }
  
  /// Default donation recipient
  static Future<DonationRecipient> get defaultRecipient async {
    final list = await presets;
    return list[_defaultIndex];
  }
  
  /// Default donation recipient (sync version)
  static DonationRecipient get defaultRecipientSync {
    return presetsSync[_defaultIndex];
  }
  
  /// Find recipient by Lightning Address
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
  
  /// Reset load state (for testing)
  static void reset() {
    _presets = [];
    _defaultIndex = 0;
    _isLoaded = false;
  }
}

