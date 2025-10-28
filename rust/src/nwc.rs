/// Nostr Wallet Connect (NWC) client implementation

use anyhow::{Context, Result};
use nostr_sdk::prelude::*;
use nostr::nips::nip47::PayInvoiceRequest;
use nwc::NWC;

pub struct NwcClient {
    nwc_uri: NostrWalletConnectURI,
}

impl NwcClient {
    /// Create new client from NWC connection string
    pub fn new(connection_string: &str) -> Result<Self> {
        println!("🔧 [NWC] Starting client creation");
        let nwc_uri = NostrWalletConnectURI::parse(connection_string)
            .context("Failed to parse NWC connection string")?;
        
        println!("✅ [NWC] Client creation successful");
        println!("   Relay: {}", nwc_uri.relay_url);
        Ok(Self { nwc_uri })
    }
    
    /// Test connection and get balance (with timeout)
    pub async fn test_connection(&self) -> Result<u64> {
        use tokio::time::{timeout, Duration};
        
        println!("🔍 [NWC] Starting connection test");
        // OK if NWC URI is correctly parsed
        // Check relay URL string representation
        if self.nwc_uri.relay_url.to_string().is_empty() {
            println!("❌ [NWC] Relay URL not set");
            anyhow::bail!("Relay URL not set");
        }
        
        println!("   Relay: {}", self.nwc_uri.relay_url);
        
        // Get balance (30 second timeout)
        println!("💰 [NWC] Fetching balance...");
        let result = timeout(
            Duration::from_secs(30),
            async {
                let nwc_client = NWC::new(self.nwc_uri.clone());
                nwc_client.get_balance().await
            }
        ).await;
        
        match result {
            Ok(Ok(balance_msats)) => {
                // Convert msats to sats (1 sats = 1000 msats)
                let balance_sats = balance_msats / 1000;
                println!("✅ [NWC] Connection test successful - balance: {} sats ({} msats)", balance_sats, balance_msats);
                Ok(balance_sats)
            }
            Ok(Err(e)) => {
                println!("❌ [NWC] Balance retrieval error: {}", e);
                Err(e.into())
            }
            Err(_) => {
                println!("⏱️ [NWC] Timeout: no response within 30 seconds");
                anyhow::bail!("NWC connection test timed out (30 seconds)")
            }
        }
    }
    
    /// Pay Invoice (with timeout)
    pub async fn pay_invoice(&self, invoice: &str) -> Result<String> {
        use tokio::time::{timeout, Duration};
        
        println!("💳 [NWC] Starting Invoice payment");
        println!("   Invoice: {}...", &invoice[..std::cmp::min(30, invoice.len())]);
        
        // Set timeout to 60 seconds
        let result = timeout(
            Duration::from_secs(60),
            self.pay_invoice_internal(invoice)
        ).await;
        
        match result {
            Ok(Ok(preimage)) => {
                println!("✅ [NWC] Payment successful!");
                println!("   Preimage: {}", &preimage[..std::cmp::min(20, preimage.len())]);
                Ok(preimage)
            }
            Ok(Err(e)) => {
                println!("❌ [NWC] Payment error: {}", e);
                Err(e)
            }
            Err(_) => {
                println!("⏱️ [NWC] Timeout: no response within 60 seconds");
                anyhow::bail!("NWC payment timed out (60 seconds)")
            }
        }
    }
    
    /// Internal implementation of Invoice payment
    async fn pay_invoice_internal(&self, invoice: &str) -> Result<String> {
        println!("🔧 [NWC] Initializing NWC client...");
        let nwc_client = NWC::new(self.nwc_uri.clone());
        println!("✅ [NWC] NWC client initialization complete");
        
        // Create PayInvoiceRequest
        let request_id = format!("pay_{}", rand::random::<u64>());
        println!("   Request ID: {}", request_id);
        
        let pay_request = PayInvoiceRequest {
            id: Some(request_id),
            invoice: invoice.to_string(),
            amount: None,
        };
        
        // pay_invoice request
        println!("📤 [NWC] Sending pay_invoice request...");
        println!("   Relay: {}", self.nwc_uri.relay_url);
        
        let response = nwc_client
            .pay_invoice(pay_request)
            .await
            .context("Invoice payment via NWC failed")?;
        
        // Return preimage
        Ok(response.preimage)
    }
}
