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

/// Initialization function
/// 
/// Advanced logging configuration for production:
/// - Structured log output (JSON format support)
/// - Level-based filtering (controllable via RUST_LOG environment variable)
/// - Timestamp and target (module name) display
/// - Android Logcat integration
/// - Performance trace support
/// - Compatibility with existing log crate
#[frb(sync)]
pub fn init() {
    INIT.call_once(|| {
        // Enable tracing to receive logs from existing log crate
        tracing_log::LogTracer::init().ok();

        // Filterable via RUST_LOG environment variable
        // Default: output INFO level and above
        // Example: RUST_LOG=debug or RUST_LOG=zap_clock=trace
        let env_filter = EnvFilter::try_from_default_env()
            .unwrap_or_else(|_| {
                EnvFilter::new("info")
                    // Enable app-specific logs up to trace level
                    .add_directive("zap_clock=trace".parse().unwrap())
                    // nostr-sdk logs at info level only
                    .add_directive("nostr_sdk=info".parse().unwrap())
                    // nwc logs at debug level and above
                    .add_directive("nwc=debug".parse().unwrap())
            });

        #[cfg(target_os = "android")]
        {
            // Android environment: output to Logcat
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
            // Non-Android environment: output structured logs to stdout
            tracing_subscriber::registry()
                .with(env_filter)
                .with(
                    fmt::layer()
                        .with_target(true)  // Display module name
                        .with_thread_ids(true)  // Display thread ID
                        .with_thread_names(true)  // Display thread name
                        .with_line_number(true)  // Display line number
                        .with_file(true)  // Display file name
                        .with_ansi(true)  // Color output
                        .compact()  // Compact output format
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

/// Return version information
#[frb(sync)]
pub fn get_version() -> String {
    env!("CARGO_PKG_VERSION").to_string()
}
