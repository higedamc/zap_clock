mod frb_generated; /* AUTO INJECTED BY flutter_rust_bridge. This line may not be accurate, and you can change it according to your needs. */
pub mod api;
pub mod nwc;
pub mod lightning;

use flutter_rust_bridge::frb;
use std::sync::Once;
use tracing_subscriber::{
    fmt,
    layer::SubscriberExt,
    util::SubscriberInitExt,
    EnvFilter,
};

static INIT: Once = Once::new();

/// 初期化関数
/// 
/// 本番環境用の高度なロギング設定:
/// - 構造化ログ出力（JSON形式対応）
/// - レベル別フィルタリング（RUST_LOG環境変数で制御可能）
/// - タイムスタンプとターゲット（モジュール名）表示
/// - Android Logcat統合
/// - パフォーマンストレース対応
/// - 既存のlog crateとの互換性
#[frb(sync)]
pub fn init() {
    INIT.call_once(|| {
        // 既存のlogクレートからのログもtracingで受け取れるようにする
        tracing_log::LogTracer::init().ok();

        // 環境変数RUST_LOGでフィルタリング可能
        // デフォルトは INFO レベル以上を出力
        // 例: RUST_LOG=debug または RUST_LOG=zap_clock=trace
        let env_filter = EnvFilter::try_from_default_env()
            .unwrap_or_else(|_| {
                EnvFilter::new("info")
                    // アプリ固有のログは trace レベルまで有効化
                    .add_directive("zap_clock=trace".parse().unwrap())
                    // nostr-sdk のログは info レベルのみ
                    .add_directive("nostr_sdk=info".parse().unwrap())
                    // nwc のログは debug レベル以上
                    .add_directive("nwc=debug".parse().unwrap())
            });

        #[cfg(target_os = "android")]
        {
            // Android環境: Logcatに出力
            let android_layer = tracing_android::layer("zap_clock")
                .expect("Failed to initialize Android logging");

            tracing_subscriber::registry()
                .with(env_filter)
                .with(android_layer)
                .init();

            tracing::info!(
                version = env!("CARGO_PKG_VERSION"),
                "ZapClock Rust library initialized (Android)"
            );
        }

        #[cfg(not(target_os = "android"))]
        {
            // 非Android環境: 標準出力に構造化ログを出力
            tracing_subscriber::registry()
                .with(env_filter)
                .with(
                    fmt::layer()
                        .with_target(true)  // モジュール名を表示
                        .with_thread_ids(true)  // スレッドIDを表示
                        .with_thread_names(true)  // スレッド名を表示
                        .with_line_number(true)  // 行番号を表示
                        .with_file(true)  // ファイル名を表示
                        .with_ansi(true)  // カラー出力
                        .compact()  // コンパクトな出力形式
                )
                .init();

            tracing::info!(
                version = env!("CARGO_PKG_VERSION"),
                platform = "non-android",
                "ZapClock Rust library initialized"
            );
        }

        tracing::debug!("Tracing subscriber initialized successfully");
    });
}

/// バージョン情報を返す
#[frb(sync)]
pub fn get_version() -> String {
    env!("CARGO_PKG_VERSION").to_string()
}

