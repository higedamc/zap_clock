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
  
  /// Enable snooze mode (2nd alarm with random timeout)
  final bool enableSnooze;
  
  /// Random timeout range for snooze (min seconds, max seconds)
  /// Only used when enableSnooze is true
  final (int, int)? snoozeTimeoutRange;
  
  const PenaltyPreset({
    required this.timeoutSeconds,
    required this.amountSats,
    required this.emoji,
    required this.nameKey,
    this.enableSnooze = false,
    this.snoozeTimeoutRange,
  });
  
  /// Preset list (snooze-based: press snooze within timeout, then stop within random 3-30s)
  static const List<PenaltyPreset> presets = [
    // Test preset
    PenaltyPreset(
      timeoutSeconds: 5, // 5 seconds to press snooze (for testing)
      amountSats: 1,
      emoji: '🧪',
      nameKey: 'penaltyPresetSnooze5s1',
      enableSnooze: true,
      snoozeTimeoutRange: (3, 10), // Random 3-10s for 2nd alarm (shorter for testing)
    ),
    PenaltyPreset(
      timeoutSeconds: 300, // 5 minutes to press snooze
      amountSats: 21,
      emoji: '⚡',
      nameKey: 'penaltyPresetSnooze5m21',
      enableSnooze: true,
      snoozeTimeoutRange: (3, 30), // Random 3-30s for 2nd alarm
    ),
    PenaltyPreset(
      timeoutSeconds: 600, // 10 minutes to press snooze
      amountSats: 100,
      emoji: '🔥',
      nameKey: 'penaltyPresetSnooze10m100',
      enableSnooze: true,
      snoozeTimeoutRange: (3, 30),
    ),
    PenaltyPreset(
      timeoutSeconds: 900, // 15 minutes to press snooze
      amountSats: 500,
      emoji: '💪',
      nameKey: 'penaltyPresetSnooze15m500',
      enableSnooze: true,
      snoozeTimeoutRange: (3, 30),
    ),
    PenaltyPreset(
      timeoutSeconds: 1800, // 30 minutes to press snooze
      amountSats: 1000,
      emoji: '😱',
      nameKey: 'penaltyPresetSnooze30m1000',
      enableSnooze: true,
      snoozeTimeoutRange: (3, 30),
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
        other.amountSats == amountSats &&
        other.enableSnooze == enableSnooze;
  }
  
  @override
  int get hashCode => Object.hash(timeoutSeconds, amountSats, enableSnooze);
}

