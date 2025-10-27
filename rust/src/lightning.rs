/// Lightning支払い処理の実装（LNURL-pay対応）

use anyhow::{Context, Result};
use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize)]
struct LnurlPayResponse {
    callback: String,
    #[serde(rename = "maxSendable")]
    max_sendable: u64,
    #[serde(rename = "minSendable")]
    min_sendable: u64,
    metadata: String,
    tag: String,
    #[serde(rename = "commentAllowed")]
    comment_allowed: Option<u64>, // コメントの最大文字数（オプション）
}

#[derive(Debug, Serialize, Deserialize)]
struct LnurlPayInvoiceResponse {
    pr: String,
    routes: Option<Vec<String>>,
}

pub struct LightningPayment {
    client: reqwest::Client,
}

impl LightningPayment {
    pub fn new() -> Self {
        Self {
            client: reqwest::Client::new(),
        }
    }
    
    /// LightningアドレスからInvoiceを取得
    pub async fn get_invoice_from_address(
        &self,
        lightning_address: &str,
        amount_sats: u64,
        comment: Option<String>,
    ) -> Result<String> {
        println!("🔍 [Lightning] Invoice取得開始: {} sats → {}", amount_sats, lightning_address);
        
        // LightningアドレスをパースしてLNURL-payエンドポイントに変換
        let parts: Vec<&str> = lightning_address.split('@').collect();
        if parts.len() != 2 {
            println!("❌ [Lightning] 無効なLightningアドレス形式: {}", lightning_address);
            anyhow::bail!("無効なLightningアドレス形式");
        }
        
        let username = parts[0];
        let domain = parts[1];
        
        // Step 1: LNURL-pay情報を取得
        let lnurl_endpoint = format!("https://{}/.well-known/lnurlp/{}", domain, username);
        println!("📡 [Lightning] LNURL-payエンドポイント: {}", lnurl_endpoint);
        
        let lnurl_response: LnurlPayResponse = self
            .client
            .get(&lnurl_endpoint)
            .send()
            .await
            .context("LNURL-payエンドポイントへのリクエストに失敗")?
            .json()
            .await
            .context("LNURL-payレスポンスのパースに失敗")?;
        
        println!("✅ [Lightning] LNURL-pay情報取得成功");
        println!("   Min: {} sats, Max: {} sats", 
            lnurl_response.min_sendable / 1000, 
            lnurl_response.max_sendable / 1000
        );
        
        // 金額のバリデーション
        let amount_msats = amount_sats * 1000;
        if amount_msats < lnurl_response.min_sendable
            || amount_msats > lnurl_response.max_sendable
        {
            println!("❌ [Lightning] 金額が範囲外: {} sats (範囲: {}-{} sats)",
                amount_sats,
                lnurl_response.min_sendable / 1000,
                lnurl_response.max_sendable / 1000
            );
            anyhow::bail!(
                "金額が範囲外です（{}-{} sats）",
                lnurl_response.min_sendable / 1000,
                lnurl_response.max_sendable / 1000
            );
        }
        
        // Step 2: Invoiceを取得
        println!("📡 [Lightning] Invoiceリクエスト: {} msats", amount_msats);
        
        // コメントの処理
        let mut query_params = vec![("amount", amount_msats.to_string())];
        if let Some(comment_text) = comment {
            if let Some(max_comment_len) = lnurl_response.comment_allowed {
                if comment_text.len() <= max_comment_len as usize {
                    println!("💬 [Lightning] コメント追加: {}", comment_text);
                    query_params.push(("comment", comment_text));
                } else {
                    println!("⚠️ [Lightning] コメントが長すぎるため省略 (最大{}文字)", max_comment_len);
                }
            } else {
                println!("⚠️ [Lightning] 受信者はコメントをサポートしていません");
            }
        }
        
        let invoice_response: LnurlPayInvoiceResponse = self
            .client
            .get(&lnurl_response.callback)
            .query(&query_params)
            .send()
            .await
            .context("Invoiceリクエストに失敗")?
            .json()
            .await
            .context("Invoiceレスポンスのパースに失敗")?;
        
        println!("✅ [Lightning] Invoice取得成功: {}", &invoice_response.pr[..20]);
        Ok(invoice_response.pr)
    }
}

impl Default for LightningPayment {
    fn default() -> Self {
        Self::new()
    }
}

