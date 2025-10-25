/// Nostr Wallet Connect (NWC) クライアントの実装

use anyhow::{Context, Result};
use nostr_sdk::prelude::*;
use nostr::nips::nip47::PayInvoiceRequest;
use nwc::NWC;

pub struct NwcClient {
    nwc_uri: NostrWalletConnectURI,
}

impl NwcClient {
    /// NWC接続文字列から新しいクライアントを作成
    pub fn new(connection_string: &str) -> Result<Self> {
        println!("🔧 [NWC] クライアント作成開始");
        let nwc_uri = NostrWalletConnectURI::parse(connection_string)
            .context("NWC接続文字列のパースに失敗")?;
        
        println!("✅ [NWC] クライアント作成成功");
        println!("   Relay: {}", nwc_uri.relay_url);
        Ok(Self { nwc_uri })
    }
    
    /// 接続をテストして残高を取得（タイムアウト付き）
    pub async fn test_connection(&self) -> Result<u64> {
        use tokio::time::{timeout, Duration};
        
        println!("🔍 [NWC] 接続テスト開始");
        // NWC URIが正しくパースできていればOK
        // リレーURLの文字列表現をチェック
        if self.nwc_uri.relay_url.to_string().is_empty() {
            println!("❌ [NWC] リレーURLが設定されていません");
            anyhow::bail!("リレーURLが設定されていません");
        }
        
        println!("   Relay: {}", self.nwc_uri.relay_url);
        
        // 残高を取得（タイムアウト30秒）
        println!("💰 [NWC] 残高取得中...");
        let result = timeout(
            Duration::from_secs(30),
            async {
                let nwc_client = NWC::new(self.nwc_uri.clone());
                nwc_client.get_balance().await
            }
        ).await;
        
        match result {
            Ok(Ok(balance_msats)) => {
                // msatsからsatsに変換（1 sats = 1000 msats）
                let balance_sats = balance_msats / 1000;
                println!("✅ [NWC] 接続テスト成功 - 残高: {} sats ({} msats)", balance_sats, balance_msats);
                Ok(balance_sats)
            }
            Ok(Err(e)) => {
                println!("❌ [NWC] 残高取得エラー: {}", e);
                Err(e.into())
            }
            Err(_) => {
                println!("⏱️ [NWC] タイムアウト: 30秒以内に応答がありませんでした");
                anyhow::bail!("NWC接続テストがタイムアウトしました（30秒）")
            }
        }
    }
    
    /// Invoiceを支払う（タイムアウト付き）
    pub async fn pay_invoice(&self, invoice: &str) -> Result<String> {
        use tokio::time::{timeout, Duration};
        
        println!("💳 [NWC] Invoice支払い開始");
        println!("   Invoice: {}...", &invoice[..std::cmp::min(30, invoice.len())]);
        
        // タイムアウトを60秒に設定
        let result = timeout(
            Duration::from_secs(60),
            self.pay_invoice_internal(invoice)
        ).await;
        
        match result {
            Ok(Ok(preimage)) => {
                println!("✅ [NWC] 支払い成功!");
                println!("   Preimage: {}", &preimage[..std::cmp::min(20, preimage.len())]);
                Ok(preimage)
            }
            Ok(Err(e)) => {
                println!("❌ [NWC] 支払いエラー: {}", e);
                Err(e)
            }
            Err(_) => {
                println!("⏱️ [NWC] タイムアウト: 60秒以内に応答がありませんでした");
                anyhow::bail!("NWC支払いがタイムアウトしました（60秒）")
            }
        }
    }
    
    /// Invoice支払いの内部実装
    async fn pay_invoice_internal(&self, invoice: &str) -> Result<String> {
        println!("🔧 [NWC] NWCクライアントを初期化中...");
        let nwc_client = NWC::new(self.nwc_uri.clone());
        println!("✅ [NWC] NWCクライアント初期化完了");
        
        // PayInvoiceRequestを作成
        let request_id = format!("pay_{}", rand::random::<u64>());
        println!("   Request ID: {}", request_id);
        
        let pay_request = PayInvoiceRequest {
            id: Some(request_id),
            invoice: invoice.to_string(),
            amount: None,
        };
        
        // pay_invoiceリクエスト
        println!("📤 [NWC] pay_invoiceリクエスト送信中...");
        println!("   Relay: {}", self.nwc_uri.relay_url);
        
        let response = nwc_client
            .pay_invoice(pay_request)
            .await
            .context("NWC経由のInvoice支払いに失敗")?;
        
        // プリイメージを返す
        Ok(response.preimage)
    }
}

