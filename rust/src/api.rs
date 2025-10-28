/// Module defining API functions called from Flutter side

use crate::lightning::LightningPayment;
use crate::nwc::NwcClient;
use flutter_rust_bridge::frb;

/// Test NWC connection and get balance
#[frb]
pub async fn test_nwc_connection(connection_string: String) -> Result<u64, String> {
    println!("📞 [API] test_nwc_connection called");
    
    let client = NwcClient::new(&connection_string)
        .map_err(|e| {
            println!("❌ [API] NWC connection initialization failed: {}", e);
            format!("NWC connection initialization failed: {}", e)
        })?;
    
    let balance = client.test_connection()
        .await
        .map_err(|e| {
            println!("❌ [API] Connection test failed: {}", e);
            format!("Connection test failed: {}", e)
        })?;
    
    println!("✅ [API] test_nwc_connection successful - balance: {} sats", balance);
    Ok(balance)
}

/// Execute Lightning payment
#[frb]
pub async fn pay_lightning_invoice(
    connection_string: String,
    lightning_address: String,
    amount_sats: u64,
    comment: Option<String>,
) -> Result<String, String> {
    println!("📞 [API] pay_lightning_invoice called");
    println!("   Address: {}", lightning_address);
    println!("   Amount: {} sats", amount_sats);
    if let Some(ref c) = comment {
        println!("   Comment: {}", c);
    }
    
    // Get Invoice from Lightning address
    let payment = LightningPayment::new();
    let invoice = payment
        .get_invoice_from_address(&lightning_address, amount_sats, comment)
        .await
        .map_err(|e| {
            println!("❌ [API] Invoice retrieval failed: {}", e);
            format!("Invoice retrieval failed: {}", e)
        })?;
    
    // Pay via NWC
    let client = NwcClient::new(&connection_string)
        .map_err(|e| {
            println!("❌ [API] NWC connection initialization failed: {}", e);
            format!("NWC connection initialization failed: {}", e)
        })?;
    
    let payment_hash = client
        .pay_invoice(&invoice)
        .await
        .map_err(|e| {
            println!("❌ [API] Payment failed: {}", e);
            format!("Payment failed: {}", e)
        })?;
    
    println!("✅ [API] pay_lightning_invoice successful");
    Ok(payment_hash)
}
