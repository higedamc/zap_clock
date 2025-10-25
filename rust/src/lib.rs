mod frb_generated; /* AUTO INJECTED BY flutter_rust_bridge. This line may not be accurate, and you can change it according to your needs. */
pub mod api;
pub mod nwc;
pub mod lightning;

use flutter_rust_bridge::frb;

/// 初期化関数
#[frb(sync)]
pub fn init() {
    // ロギングの初期化などを行う
    // 本番環境ではより高度なロギング設定を行う
}

/// バージョン情報を返す
#[frb(sync)]
pub fn get_version() -> String {
    env!("CARGO_PKG_VERSION").to_string()
}

