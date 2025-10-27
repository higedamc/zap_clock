import 'package:flutter/material.dart';
import '../bridge_generated.dart/frb_generated.dart';
import '../bridge_generated.dart/api.dart' as rust_api;

/// NWC (Nostr Wallet Connect) サービス
/// 
/// Rust側のNWCクライアントとの橋渡しを行う
class NwcService {
  // Rustブリッジの初期化（一度だけ実行）
  static Future<void> initialize() async {
    try {
      await RustLib.init();
      debugPrint('✅ Rust bridge initialized');
    } catch (e) {
      debugPrint('⚠️ Rust bridge initialization failed (using mock): $e');
    }
  }
  
  /// NWC接続をテストして残高を取得
  Future<int> testConnection(String connectionString) async {
    try {
      // Rustブリッジを使用（残高を返す）
      final balance = await rust_api.testNwcConnection(
        connectionString: connectionString,
      );
      debugPrint('✅ NWC接続成功 - 残高: $balance sats');
      return balance.toInt();
    } catch (e) {
      debugPrint('❌ NWC接続失敗: $e');
      rethrow;
    }
  }
  
  /// Lightning Invoiceを支払う（設定された送金先に送金）
  Future<String> payWithNwc({
    required String connectionString,
    required String lightningAddress,
    required int amountSats,
    String? comment,
  }) async {
    try {
      debugPrint('🔄 NWC送金開始: $amountSats sats → $lightningAddress');
      if (comment != null) {
        debugPrint('💬 コメント: $comment');
      }
      
      // Rustブリッジを使用
      final paymentHash = await rust_api.payLightningInvoice(
        connectionString: connectionString,
        lightningAddress: lightningAddress,
        amountSats: BigInt.from(amountSats),
        comment: comment,
      );
      
      debugPrint('✅ NWC送金成功: $paymentHash');
      return paymentHash;
    } catch (e) {
      debugPrint('❌ NWC送金失敗: $e');
      rethrow; // エラーを上位に伝播
    }
  }
  
  /// Lightning Invoiceを支払う（旧メソッド - 互換性のため残す）
  Future<String> payInvoice({
    required String connectionString,
    required String lightningAddress,
    required int amountSats,
    String? comment,
  }) async {
    try {
      // Rustブリッジを使用
      final paymentHash = await rust_api.payLightningInvoice(
        connectionString: connectionString,
        lightningAddress: lightningAddress,
        amountSats: BigInt.from(amountSats),
        comment: comment,
      );
      return paymentHash;
    } catch (e) {
      // エラー時はモックにフォールバック
      debugPrint('⚠️ Rust API failed, using mock: $e');
      debugPrint('⚡ Lightning送金（モック）: $amountSats sats → $lightningAddress');
      await Future.delayed(const Duration(seconds: 2));
      return 'payment_hash_mock_${DateTime.now().millisecondsSinceEpoch}';
    }
  }
}

