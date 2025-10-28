/// Penalty preset (timeout and amount combination)
class PenaltyPreset {
  /// Timeout duration (seconds)
  final int timeoutSeconds;
  
  /// Payment amount (sats)
  final int amountSats;
  
  /// Emoji
  final String emoji;
  
  /// Localization key (referenced in l10n)
  final String nameKey;
  
  const PenaltyPreset({
    required this.timeoutSeconds,
    required this.amountSats,
    required this.emoji,
    required this.nameKey,
  });
  
  /// Preset list
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
  
  /// Special instance for custom preset (for UI display)
  static const PenaltyPreset custom = PenaltyPreset(
    timeoutSeconds: -1,
    amountSats: -1,
    emoji: '⚙️',
    nameKey: 'penaltyPresetCustom',
  );
  
  /// Get preset closest to specified timeout and amount
  /// For migration
  static PenaltyPreset? findClosestPreset(int? timeoutSeconds, int? amountSats) {
    if (timeoutSeconds == null || amountSats == null) {
      return null;
    }
    
    // Find exact match
    for (final preset in presets) {
      if (preset.timeoutSeconds == timeoutSeconds && preset.amountSats == amountSats) {
        return preset;
      }
    }
    
    // Find matching timeout
    for (final preset in presets) {
      if (preset.timeoutSeconds == timeoutSeconds) {
        return preset;
      }
    }
    
    // Return null if not found (treat as custom)
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

