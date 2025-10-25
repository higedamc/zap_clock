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
}

/// 送金先プリセットリスト
class DonationRecipients {
  /// プリセット一覧
  static const List<DonationRecipient> presets = [
    DonationRecipient(
      name: 'ZapClock Developer (soggyhack)',
      lightningAddress: 'soggyhack118@walletofsatoshi.com',
      description: 'Creator of ZapClock alarm app',
      emoji: '⚡',
    ),
    DonationRecipient(
      name: 'Human Rights Foundation',
      lightningAddress: 'hrf@geyser.fund',
      description: 'Fighting for freedom around the world',
      emoji: '🌍',
    ),
    DonationRecipient(
      name: 'Zeus Wallet Developer',
      lightningAddress: 'evan@getalby.com',
      description: 'Mobile Lightning wallet development',
      emoji: '📱',
    ),
    DonationRecipient(
      name: 'Sparrow Wallet Developer',
      lightningAddress: 'craig@sparrowwallet.com',
      description: 'Bitcoin desktop wallet development',
      emoji: '🐦',
    ),
    DonationRecipient(
      name: 'OpenSats',
      lightningAddress: 'donate@opensats.org',
      description: 'Supporting open source Bitcoin projects',
      emoji: '🧡',
    ),
    DonationRecipient(
      name: 'Bitcoin Design Community',
      lightningAddress: 'tips@bitcoin.design',
      description: 'Improving Bitcoin UX/UI',
      emoji: '🎨',
    ),
  ];
  
  /// デフォルトの送金先（ZapClock Developer）
  static DonationRecipient get defaultRecipient => presets[0];
  
  /// Lightning Addressから受取人を検索
  static DonationRecipient? findByAddress(String lightningAddress) {
    try {
      return presets.firstWhere(
        (recipient) => recipient.lightningAddress == lightningAddress,
      );
    } catch (e) {
      return null;
    }
  }
}

