/// アラームのデータモデル
class Alarm {
  /// アラームID（ユニーク）
  final int id;
  
  /// アラーム時刻（時）
  final int hour;
  
  /// アラーム時刻（分）
  final int minute;
  
  /// 有効/無効
  final bool isEnabled;
  
  /// アラームラベル
  final String label;
  
  /// 繰り返し設定（曜日）
  /// [月, 火, 水, 木, 金, 土, 日]
  final List<bool> repeatDays;
  
  /// 送金額（sats）（NWC送金に使用）
  final int? amountSats;
  
  /// タイムアウト時間（秒）
  /// この時間が経過すると自動的に送金される
  final int? timeoutSeconds;
  
  /// 送金先Lightning Address（このアラーム固有の送金先）
  final String? donationRecipient;
  
  /// アラーム音源のパス（nullの場合はデフォルト音源を使用）
  final String? soundPath;
  
  /// アラーム音源の表示名
  final String? soundName;
  
  Alarm({
    required this.id,
    required this.hour,
    required this.minute,
    this.isEnabled = true,
    this.label = '',
    List<bool>? repeatDays,
    this.amountSats,
    this.timeoutSeconds = 300, // デフォルト5分=300秒
    this.donationRecipient,
    this.soundPath,
    this.soundName,
  }) : repeatDays = repeatDays ?? List.filled(7, false);
  
  /// 時刻を文字列で取得（例: "07:30"）
  String get timeString {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
  
  /// 繰り返しが設定されているか
  bool get hasRepeat {
    return repeatDays.any((day) => day);
  }
  
  /// 繰り返し曜日を日本語文字列で取得
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
    
    // 全曜日が選択されている場合
    if (selectedDays.length == 7) {
      return '毎日';
    }
    
    // 平日のみ
    if (selectedDays.length == 5 && 
        repeatDays[0] && repeatDays[1] && repeatDays[2] && 
        repeatDays[3] && repeatDays[4]) {
      return '平日';
    }
    
    // 週末のみ
    if (selectedDays.length == 2 && repeatDays[5] && repeatDays[6]) {
      return '週末';
    }
    
    return selectedDays.join(', ');
  }
  
  /// 繰り返し曜日をローカライズされた文字列で取得
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
    
    // 全曜日が選択されている場合
    if (selectedDays.length == 7) {
      return l10n.everyday;
    }
    
    // 平日のみ
    if (selectedDays.length == 5 && 
        repeatDays[0] && repeatDays[1] && repeatDays[2] && 
        repeatDays[3] && repeatDays[4]) {
      return l10n.weekdays;
    }
    
    // 週末のみ
    if (selectedDays.length == 2 && repeatDays[5] && repeatDays[6]) {
      return l10n.weekend;
    }
    
    return selectedDays.join(', ');
  }
  
  /// 次回のアラーム発火時刻を取得
  DateTime getNextAlarmTime() {
    final now = DateTime.now();
    var next = DateTime(now.year, now.month, now.day, hour, minute);
    
    // 繰り返しが設定されていない場合
    if (!hasRepeat) {
      // 今日の時刻がすでに過ぎていたら明日
      if (next.isBefore(now)) {
        next = next.add(const Duration(days: 1));
      }
      return next;
    }
    
    // 繰り返しが設定されている場合、次に該当する曜日を探す
    for (int i = 0; i < 8; i++) {
      final checkDate = next.add(Duration(days: i));
      final weekday = (checkDate.weekday - 1) % 7; // 月曜=0, 日曜=6に変換
      
      if (repeatDays[weekday] && checkDate.isAfter(now)) {
        return checkDate;
      }
    }
    
    return next;
  }
  
  /// JSON形式に変換（SharedPreferences保存用）
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
  
  /// JSONから復元
  factory Alarm.fromJson(Map<String, dynamic> json) {
    // 後方互換性：timeoutMinutesが存在する場合は秒に変換
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
  
  /// コピーメソッド（値の一部を変更した新しいインスタンスを作成）
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

