/// Lightning payment processing implementation (LNURL-pay support)

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
    comment_allowed: Option<u64>, // Maximum comment characters (optional)
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
    
    /// Get Invoice from Lightning address
    pub async fn get_invoice_from_address(
        &self,
        lightning_address: &str,
        amount_sats: u64,
        comment: Option<String>,
    ) -> Result<String> {
        println!("🔍 [Lightning] Starting Invoice retrieval: {} sats → {}", amount_sats, lightning_address);
        
        // Parse Lightning address and convert to LNURL-pay endpoint
        let parts: Vec<&str> = lightning_address.split('@').collect();
        if parts.len() != 2 {
            println!("❌ [Lightning] Invalid Lightning address format: {}", lightning_address);
            anyhow::bail!("Invalid Lightning address format");
        }
        
        let username = parts[0];
        let domain = parts[1];
        
        // Step 1: Get LNURL-pay information
        let lnurl_endpoint = format!("https://{}/.well-known/lnurlp/{}", domain, username);
        println!("📡 [Lightning] LNURL-pay endpoint: {}", lnurl_endpoint);
        
        let lnurl_response: LnurlPayResponse = self
            .client
            .get(&lnurl_endpoint)
            .send()
            .await
            .context("Request to LNURL-pay endpoint failed")?
            .json()
            .await
            .context("Failed to parse LNURL-pay response")?;
        
        println!("✅ [Lightning] LNURL-pay information retrieved successfully");
        println!("   Min: {} sats, Max: {} sats", 
            lnurl_response.min_sendable / 1000, 
            lnurl_response.max_sendable / 1000
        );
        
        // Amount validation
        let amount_msats = amount_sats * 1000;
        if amount_msats < lnurl_response.min_sendable
            || amount_msats > lnurl_response.max_sendable
        {
            println!("❌ [Lightning] Amount out of range: {} sats (range: {}-{} sats)",
                amount_sats,
                lnurl_response.min_sendable / 1000,
                lnurl_response.max_sendable / 1000
            );
            anyhow::bail!(
                "Amount out of range ({}-{} sats)",
                lnurl_response.min_sendable / 1000,
                lnurl_response.max_sendable / 1000
            );
        }
        
        // Step 2: Get Invoice
        println!("📡 [Lightning] Invoice request: {} msats", amount_msats);
        
        // Comment processing
        let mut query_params = vec![("amount", amount_msats.to_string())];
        if let Some(comment_text) = comment {
            if let Some(max_comment_len) = lnurl_response.comment_allowed {
                if comment_text.len() <= max_comment_len as usize {
                    println!("💬 [Lightning] Adding comment: {}", comment_text);
                    query_params.push(("comment", comment_text));
                } else {
                    println!("⚠️ [Lightning] Comment too long, omitted (max {} chars)", max_comment_len);
                }
            } else {
                println!("⚠️ [Lightning] Recipient does not support comments");
            }
        }
        
        let invoice_response: LnurlPayInvoiceResponse = self
            .client
            .get(&lnurl_response.callback)
            .query(&query_params)
            .send()
            .await
            .context("Invoice request failed")?
            .json()
            .await
            .context("Failed to parse Invoice response")?;
        
        println!("✅ [Lightning] Invoice retrieved successfully: {}", &invoice_response.pr[..20]);
        Ok(invoice_response.pr)
    }
}

impl Default for LightningPayment {
    fn default() -> Self {
        Self::new()
    }
}
