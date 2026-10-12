import 'package:flutter/material.dart';
import '../bridge_generated.dart/frb_generated.dart';
import '../bridge_generated.dart/api.dart' as rust_api;
import 'payment_mode.dart';
import 'zap_executor.dart';

/// NWC (Nostr Wallet Connect) service
/// 
/// Bridge to Rust-side NWC client
class NwcService implements LightningPayer {
  // Initialize Rust bridge (execute only once)
  static Future<void> initialize() async {
    try {
      await RustLib.init();
      debugPrint('✅ Rust bridge initialized');
    } catch (e) {
      debugPrint('⚠️ Rust bridge initialization failed: $e');
    }
  }
  
  /// Test NWC connection and get balance
  Future<int> testConnection(String connectionString) async {
    try {
      // Use Rust bridge (returns balance)
      final balance = await rust_api.testNwcConnection(
        connectionString: connectionString,
      );
      debugPrint('✅ NWC connection successful - balance: $balance sats');
      return balance.toInt();
    } catch (e) {
      debugPrint('❌ NWC connection failed: $e');
      rethrow;
    }
  }
  
  /// Pay Lightning Invoice (send to configured destination)
  Future<String> payWithNwc({
    required String connectionString,
    required String lightningAddress,
    required int amountSats,
    String? comment,
  }) async {
    try {
      debugPrint('🔄 Starting NWC payment: $amountSats sats → $lightningAddress');
      if (comment != null) {
        debugPrint('💬 Comment: $comment');
      }
      
      // Use Rust bridge
      final paymentHash = await rust_api.payLightningInvoice(
        connectionString: connectionString,
        lightningAddress: lightningAddress,
        amountSats: BigInt.from(amountSats),
        comment: comment,
      );
      
      debugPrint('✅ NWC payment successful: $paymentHash');
      return paymentHash;
    } catch (e) {
      debugPrint('❌ NWC payment failed: $e');
      rethrow; // Propagate error to caller
    }
  }
  
  @override
  Future<String> pay({
    required String connectionString,
    required String lightningAddress,
    required int amountSats,
    String? comment,
  }) async {
    if (kDryRunPayments) {
      // Compile-time switch (--dart-define=ZAPCLOCK_DRY_RUN_PAYMENTS=true).
      // Everything upstream behaves exactly as in production; only the wallet
      // call is replaced.
      debugPrint('🧪 DRY RUN: would pay $amountSats sats → $lightningAddress');
      return 'dryrun-${DateTime.now().millisecondsSinceEpoch}';
    }
    return payWithNwc(
      connectionString: connectionString,
      lightningAddress: lightningAddress,
      amountSats: amountSats,
      comment: comment,
    );
  }
}
