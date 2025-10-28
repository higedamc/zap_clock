/// Alarm data model
class Alarm {
  /// Alarm ID (unique)
  final int id;
  
  /// Alarm time (hour)
  final int hour;
  
  /// Alarm time (minute)
  final int minute;
  
  /// Enabled/disabled status
  final bool isEnabled;
  
  /// Alarm label
  final String label;
  
  /// Repeat settings (day of week)
  /// [Mon, Tue, Wed, Thu, Fri, Sat, Sun]
  final List<bool> repeatDays;
  
  /// Payment amount (sats) (used for NWC payment)
  final int? amountSats;
  
  /// Timeout duration (seconds)
  /// Payment is automatically made after this time
  final int? timeoutSeconds;
  
  /// Payment destination Lightning Address (specific to this alarm)
  final String? donationRecipient;
  
  /// Alarm sound path (uses default if null)
  final String? soundPath;
  
  /// Alarm sound display name
  final String? soundName;
  
  Alarm({
    required this.id,
    required this.hour,
    required this.minute,
    this.isEnabled = true,
    this.label = '',
    List<bool>? repeatDays,
    this.amountSats,
    this.timeoutSeconds = 300, // Default 5 minutes = 300 seconds
    this.donationRecipient,
    this.soundPath,
    this.soundName,
  }) : repeatDays = repeatDays ?? List.filled(7, false);
  
  /// Get time as string (e.g., "07:30")
  String get timeString {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
  
  /// Check if repeat is set
  bool get hasRepeat {
    return repeatDays.any((day) => day);
  }
  
  /// Get repeat days as Japanese string
  /// @deprecated Use getRepeatDaysString(l10n) instead for proper localization
  String get repeatDaysString {
    if (!hasRepeat) {
      return '1回のみ';
    }
    
    const dayNames = ['月', '火', '水', '木', '金', '土', '日'];
    final selectedDays = <String>[];
    
    for (int i = 0; i < 7; i++) {
      if (repeatDays[i]) {
        selectedDays.add(dayNames[i]);
      }
    }
    
    // All days selected
    if (selectedDays.length == 7) {
      return '毎日';
    }
    
    // Weekdays only
    if (selectedDays.length == 5 && 
        repeatDays[0] && repeatDays[1] && repeatDays[2] && 
        repeatDays[3] && repeatDays[4]) {
      return '平日';
    }
    
    // Weekends only
    if (selectedDays.length == 2 && repeatDays[5] && repeatDays[6]) {
      return '週末';
    }
    
    return selectedDays.join(', ');
  }
  
  /// Get repeat days as localized string
  String getRepeatDaysString(dynamic l10n) {
    if (!hasRepeat) {
      return l10n.onceOnly;
    }
    
    final dayNames = [
      l10n.monday,
      l10n.tuesday,
      l10n.wednesday,
      l10n.thursday,
      l10n.friday,
      l10n.saturday,
      l10n.sunday,
    ];
    final selectedDays = <String>[];
    
    for (int i = 0; i < 7; i++) {
      if (repeatDays[i]) {
        selectedDays.add(dayNames[i]);
      }
    }
    
    // All days selected
    if (selectedDays.length == 7) {
      return l10n.everyday;
    }
    
    // Weekdays only
    if (selectedDays.length == 5 && 
        repeatDays[0] && repeatDays[1] && repeatDays[2] && 
        repeatDays[3] && repeatDays[4]) {
      return l10n.weekdays;
    }
    
    // Weekends only
    if (selectedDays.length == 2 && repeatDays[5] && repeatDays[6]) {
      return l10n.weekend;
    }
    
    return selectedDays.join(', ');
  }
  
  /// Get next alarm trigger time
  DateTime getNextAlarmTime() {
    final now = DateTime.now();
    var next = DateTime(now.year, now.month, now.day, hour, minute);
    
    // If no repeat is set
    if (!hasRepeat) {
      // If time has already passed today, set to tomorrow
      if (next.isBefore(now)) {
        next = next.add(const Duration(days: 1));
      }
      return next;
    }
    
    // If repeat is set, find next matching day
    for (int i = 0; i < 8; i++) {
      final checkDate = next.add(Duration(days: i));
      final weekday = (checkDate.weekday - 1) % 7; // Convert Monday=0, Sunday=6
      
      if (repeatDays[weekday] && checkDate.isAfter(now)) {
        return checkDate;
      }
    }
    
    return next;
  }
  
  /// Convert to JSON (for SharedPreferences)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hour': hour,
      'minute': minute,
      'isEnabled': isEnabled,
      'label': label,
      'repeatDays': repeatDays,
      'amountSats': amountSats,
      'timeoutSeconds': timeoutSeconds,
      'donationRecipient': donationRecipient,
      'soundPath': soundPath,
      'soundName': soundName,
    };
  }
  
  /// Restore from JSON
  factory Alarm.fromJson(Map<String, dynamic> json) {
    // Backward compatibility: convert timeoutMinutes to seconds if exists
    int? timeoutSecs = json['timeoutSeconds'] as int?;
    if (timeoutSecs == null && json['timeoutMinutes'] != null) {
      timeoutSecs = (json['timeoutMinutes'] as int) * 60;
    }
    
    return Alarm(
      id: json['id'] as int,
      hour: json['hour'] as int,
      minute: json['minute'] as int,
      isEnabled: json['isEnabled'] as bool? ?? true,
      label: json['label'] as String? ?? '',
      repeatDays: (json['repeatDays'] as List?)?.cast<bool>(),
      amountSats: json['amountSats'] as int?,
      timeoutSeconds: timeoutSecs ?? 300,
      donationRecipient: json['donationRecipient'] as String?,
      soundPath: json['soundPath'] as String?,
      soundName: json['soundName'] as String?,
    );
  }
  
  /// Copy method (create new instance with some values modified)
  Alarm copyWith({
    int? id,
    int? hour,
    int? minute,
    bool? isEnabled,
    String? label,
    List<bool>? repeatDays,
    int? amountSats,
    int? timeoutSeconds,
    String? donationRecipient,
    String? soundPath,
    String? soundName,
  }) {
    return Alarm(
      id: id ?? this.id,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      isEnabled: isEnabled ?? this.isEnabled,
      label: label ?? this.label,
      repeatDays: repeatDays ?? List.from(this.repeatDays),
      amountSats: amountSats ?? this.amountSats,
      timeoutSeconds: timeoutSeconds ?? this.timeoutSeconds,
      donationRecipient: donationRecipient ?? this.donationRecipient,
      soundPath: soundPath ?? this.soundPath,
      soundName: soundName ?? this.soundName,
    );
  }
  
  @override
  String toString() {
    return 'Alarm(id: $id, time: $timeString, enabled: $isEnabled, label: $label)';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is Alarm &&
        other.id == id &&
        other.hour == hour &&
        other.minute == minute &&
        other.isEnabled == isEnabled &&
        other.label == label;
  }
  
  @override
  int get hashCode {
    return Object.hash(id, hour, minute, isEnabled, label);
  }
}

