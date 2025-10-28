/// ペナルティプリセット（タイムアウトと金額の組み合わせ）
class PenaltyPreset {
  /// タイムアウト時間（秒）
  final int timeoutSeconds;
  
  /// 送金額（sats）
  final int amountSats;
  
  /// 絵文字
  final String emoji;
  
  /// ローカライズキー（l10nで参照）
  final String nameKey;
  
  const PenaltyPreset({
    required this.timeoutSeconds,
    required this.amountSats,
    required this.emoji,
    required this.nameKey,
  });
  
  /// プリセット一覧
  static const List<PenaltyPreset> presets = [
    PenaltyPreset(
      timeoutSeconds: 15,
      amountSats: 21,
      emoji: '⚡',
      nameKey: 'penaltyPreset15s',
    ),
    PenaltyPreset(
      timeoutSeconds: 30,
      amountSats: 42,
      emoji: '🔥',
      nameKey: 'penaltyPreset30s',
    ),
    PenaltyPreset(
      timeoutSeconds: 60,
      amountSats: 100,
      emoji: '💪',
      nameKey: 'penaltyPreset1m',
    ),
    PenaltyPreset(
      timeoutSeconds: 300,
      amountSats: 500,
      emoji: '😴',
      nameKey: 'penaltyPreset5m',
    ),
    PenaltyPreset(
      timeoutSeconds: 600,
      amountSats: 1000,
      emoji: '😱',
      nameKey: 'penaltyPreset10m',
    ),
    PenaltyPreset(
      timeoutSeconds: 900,
      amountSats: 2100,
      emoji: '💀',
      nameKey: 'penaltyPreset15m',
    ),
  ];
  
  /// カスタムプリセット用の特殊なインスタンス（UI表示用）
  static const PenaltyPreset custom = PenaltyPreset(
    timeoutSeconds: -1,
    amountSats: -1,
    emoji: '⚙️',
    nameKey: 'penaltyPresetCustom',
  );
  
  /// 指定されたtimeoutとamountに最も近いプリセットを取得
  /// マイグレーション用
  static PenaltyPreset? findClosestPreset(int? timeoutSeconds, int? amountSats) {
    if (timeoutSeconds == null || amountSats == null) {
      return null;
    }
    
    // 完全一致を探す
    for (final preset in presets) {
      if (preset.timeoutSeconds == timeoutSeconds && preset.amountSats == amountSats) {
        return preset;
      }
    }
    
    // タイムアウトが一致するものを探す
    for (final preset in presets) {
      if (preset.timeoutSeconds == timeoutSeconds) {
        return preset;
      }
    }
    
    // 見つからない場合はnull（カスタム扱い）
    return null;
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PenaltyPreset &&
        other.timeoutSeconds == timeoutSeconds &&
        other.amountSats == amountSats;
  }
  
  @override
  int get hashCode => Object.hash(timeoutSeconds, amountSats);
}

