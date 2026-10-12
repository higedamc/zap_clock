/// Lifecycle of a zap that an alarm may owe.
enum ZapObligationStatus {
  /// Reserved at scheduling time; nothing has happened yet.
  pending,

  /// A payment request is about to be (or was) sent. Written *before* the
  /// wallet is contacted so a crash mid-payment can never lead to a second
  /// attempt.
  attempted,

  /// The wallet confirmed the payment.
  paid,

  /// The wallet rejected or the request failed. Never retried.
  failed,

  /// The alarm was stopped before the deadline. Nothing is owed.
  cancelled,

  /// The deadline passed while the app was not running and there is no
  /// record proving the alarm rang through it. Nothing is paid.
  unprovable,
}

/// One scheduled ring that carries a payment if it is not stopped in time.
///
/// Keyed by alarm id plus the scheduled ring time, so a reschedule of the
/// same alarm creates a new obligation and an old one can never be mistaken
/// for it. The deadline is fixed when the ring is scheduled; for the second
/// snooze ring the random timeout is drawn here, not when the screen appears.
class ZapObligation {
  const ZapObligation({
    required this.alarmId,
    required this.ringAt,
    required this.deadline,
    required this.amountSats,
    required this.recipient,
    this.status = ZapObligationStatus.pending,
    this.attemptedAt,
    this.settledAt,
    this.paymentHash,
    this.error,
  });

  final int alarmId;
  final DateTime ringAt;
  final DateTime deadline;
  final int amountSats;
  final String recipient;
  final ZapObligationStatus status;
  final DateTime? attemptedAt;
  final DateTime? settledAt;
  final String? paymentHash;
  final String? error;

  String get key => keyFor(alarmId, ringAt);

  static String keyFor(int alarmId, DateTime ringAt) =>
      '$alarmId:${ringAt.millisecondsSinceEpoch}';

  bool get isPending => status == ZapObligationStatus.pending;

  ZapObligation copyWith({
    ZapObligationStatus? status,
    DateTime? attemptedAt,
    DateTime? settledAt,
    String? paymentHash,
    String? error,
  }) {
    return ZapObligation(
      alarmId: alarmId,
      ringAt: ringAt,
      deadline: deadline,
      amountSats: amountSats,
      recipient: recipient,
      status: status ?? this.status,
      attemptedAt: attemptedAt ?? this.attemptedAt,
      settledAt: settledAt ?? this.settledAt,
      paymentHash: paymentHash ?? this.paymentHash,
      error: error ?? this.error,
    );
  }

  Map<String, dynamic> toJson() => {
        'alarmId': alarmId,
        'ringAt': ringAt.millisecondsSinceEpoch,
        'deadline': deadline.millisecondsSinceEpoch,
        'amountSats': amountSats,
        'recipient': recipient,
        'status': status.name,
        'attemptedAt': attemptedAt?.millisecondsSinceEpoch,
        'settledAt': settledAt?.millisecondsSinceEpoch,
        'paymentHash': paymentHash,
        'error': error,
      };

  factory ZapObligation.fromJson(Map<String, dynamic> json) {
    DateTime? millis(Object? value) =>
        value is int ? DateTime.fromMillisecondsSinceEpoch(value) : null;
    return ZapObligation(
      alarmId: json['alarmId'] as int,
      ringAt: millis(json['ringAt'])!,
      deadline: millis(json['deadline'])!,
      amountSats: json['amountSats'] as int,
      recipient: json['recipient'] as String,
      status: ZapObligationStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => ZapObligationStatus.unprovable,
      ),
      attemptedAt: millis(json['attemptedAt']),
      settledAt: millis(json['settledAt']),
      paymentHash: json['paymentHash'] as String?,
      error: json['error'] as String?,
    );
  }

  @override
  String toString() =>
      'ZapObligation($key, ${status.name}, $amountSats sats → $recipient, '
      'deadline=$deadline)';
}
