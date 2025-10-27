/// Flutter側から呼び出されるAPI関数を定義するモジュール

use crate::lightning::LightningPayment;
use crate::nwc::NwcClient;
use flutter_rust_bridge::frb;

/// NWC接続をテストして残高を取得
#[frb]
pub async fn test_nwc_connection(connection_string: String) -> Result<u64, String> {
    println!("📞 [API] test_nwc_connection 呼び出し");
    
    let client = NwcClient::new(&connection_string)
        .map_err(|e| {
            println!("❌ [API] NWC接続の初期化に失敗: {}", e);
            format!("NWC接続の初期化に失敗: {}", e)
        })?;
    
    let balance = client.test_connection()
        .await
        .map_err(|e| {
            println!("❌ [API] 接続テストに失敗: {}", e);
            format!("接続テストに失敗: {}", e)
        })?;
    
    println!("✅ [API] test_nwc_connection 成功 - 残高: {} sats", balance);
    Ok(balance)
}

/// Lightning送金を実行する
#[frb]
pub async fn pay_lightning_invoice(
    connection_string: String,
    lightning_address: String,
    amount_sats: u64,
    comment: Option<String>,
) -> Result<String, String> {
    println!("📞 [API] pay_lightning_invoice 呼び出し");
    println!("   Address: {}", lightning_address);
    println!("   Amount: {} sats", amount_sats);
    if let Some(ref c) = comment {
        println!("   Comment: {}", c);
    }
    
    // LightningアドレスからInvoiceを取得
    let payment = LightningPayment::new();
    let invoice = payment
        .get_invoice_from_address(&lightning_address, amount_sats, comment)
        .await
        .map_err(|e| {
            println!("❌ [API] Invoice取得に失敗: {}", e);
            format!("Invoice取得に失敗: {}", e)
        })?;
    
    // NWC経由で支払い
    let client = NwcClient::new(&connection_string)
        .map_err(|e| {
            println!("❌ [API] NWC接続の初期化に失敗: {}", e);
            format!("NWC接続の初期化に失敗: {}", e)
        })?;
    
    let payment_hash = client
        .pay_invoice(&invoice)
        .await
        .map_err(|e| {
            println!("❌ [API] 支払いに失敗: {}", e);
            format!("支払いに失敗: {}", e)
        })?;
    
    println!("✅ [API] pay_lightning_invoice 成功");
    Ok(payment_hash)
}

