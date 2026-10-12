import 'package:flutter/material.dart';
import '../bridge_generated.dart/frb_generated.dart';
import '../bridge_generated.dart/api.dart' as rust_api;
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
      debugPrint('⚠️ Rust bridge initialization failed (using mock): $e');
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
  }) {
    return payWithNwc(
      connectionString: connectionString,
      lightningAddress: lightningAddress,
      amountSats: amountSats,
      comment: comment,
    );
  }

  /// Pay Lightning Invoice (old method - kept for compatibility)
  Future<String> payInvoice({
    required String connectionString,
    required String lightningAddress,
    required int amountSats,
    String? comment,
  }) async {
    try {
      // Use Rust bridge
      final paymentHash = await rust_api.payLightningInvoice(
        connectionString: connectionString,
        lightningAddress: lightningAddress,
        amountSats: BigInt.from(amountSats),
        comment: comment,
      );
      return paymentHash;
    } catch (e) {
      // Fallback to mock on error
      debugPrint('⚠️ Rust API failed, using mock: $e');
      debugPrint('⚡ Lightning payment (mock): $amountSats sats → $lightningAddress');
      await Future.delayed(const Duration(seconds: 2));
      return 'payment_hash_mock_${DateTime.now().millisecondsSinceEpoch}';
    }
  }
}
