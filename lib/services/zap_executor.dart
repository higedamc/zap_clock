import 'package:flutter/foundation.dart';

import '../models/alarm.dart';
import '../models/donation_recipient.dart';
import 'storage_service.dart';

/// The one thing that moves money. [NwcService] implements it in production;
/// tests inject a fake.
abstract class LightningPayer {
  Future<String> pay({
    required String connectionString,
    required String lightningAddress,
    required int amountSats,
    String? comment,
  });
}

/// Result of a single zap attempt.
class ZapOutcome {
  const ZapOutcome._({
    required this.attempted,
    this.paymentHash,
    this.error,
    this.skippedReason,
  });

  const ZapOutcome.paid(String paymentHash)
      : this._(attempted: true, paymentHash: paymentHash);

  const ZapOutcome.failed(Object error)
      : this._(attempted: true, error: error);

  const ZapOutcome.skipped(String reason)
      : this._(attempted: false, skippedReason: reason);

  /// True when a payment request was actually sent to the wallet.
  final bool attempted;
  final String? paymentHash;
  final Object? error;
  final String? skippedReason;

  bool get paid => attempted && paymentHash != null;

  @override
  String toString() => paid
      ? 'ZapOutcome.paid($paymentHash)'
      : attempted
          ? 'ZapOutcome.failed($error)'
          : 'ZapOutcome.skipped($skippedReason)';
}

/// Single implementation of the auto-zap. Resolves the wallet connection and
/// the recipient, sends exactly one payment request and never retries.
class ZapExecutor {
  ZapExecutor({required StorageService storage, required LightningPayer payer})
      : _storage = storage,
        _payer = payer;

  final StorageService _storage;
  final LightningPayer _payer;

  static const String comment = 'donation from ZapClock';

  /// Resolves the destination the same way for every caller: the alarm's own
  /// override, then the global setting, then the bundled default.
  String resolveRecipient(Alarm alarm) {
    return alarm.donationRecipient ??
        _storage.getDonationRecipient() ??
        DonationRecipients.defaultRecipientSync.lightningAddress;
  }

  /// Sends one payment of [amountSats] to [recipient]. Both come from the
  /// obligation that was reserved when the ring was scheduled, so a later
  /// edit of the alarm cannot change what an already-ringing alarm pays.
  Future<ZapOutcome> execute({
    required int amountSats,
    required String recipient,
    String label = '',
  }) async {
    final connection = _storage.getGlobalNwcConnection();
    if (connection == null || connection.isEmpty) {
      debugPrint('⚠️ $label: no NWC connection configured, skipping zap');
      return const ZapOutcome.skipped('no NWC connection configured');
    }

    debugPrint('💳 $label: auto zap $amountSats sats → $recipient');

    try {
      final paymentHash = await _payer.pay(
        connectionString: connection,
        lightningAddress: recipient,
        amountSats: amountSats,
        comment: comment,
      );
      debugPrint('✅ $label: zap paid ($paymentHash)');
      return ZapOutcome.paid(paymentHash);
    } catch (e) {
      debugPrint('❌ $label: zap failed: $e');
      return ZapOutcome.failed(e);
    }
  }
}
