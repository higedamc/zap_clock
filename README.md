# ZapClock ⚡⏰

**An Alarm App That Stops with Lightning Payments**

ZapClock is a funny alarm app powered by the Bitcoin Lightning Network. The alarm stops only after you send a specified amount via Lightning. With the compelling force of "pay to wake up," you'll never oversleep again!

**✨ Version 1.0.0 - First Public Release! ✨**

<br>

<p align="center">
  <img src="https://img.shields.io/badge/Version-1.0.0-brightgreen?logo=github" />
  <img src="https://img.shields.io/badge/Flutter-3.9.2-02569B?logo=flutter" />
  <img src="https://img.shields.io/badge/Rust-1.75-orange?logo=rust" />
  <img src="https://img.shields.io/badge/Lightning-Enabled-yellow?logo=lightning" />
  <img src="https://img.shields.io/badge/Nostr-NWC-purple?logo=nostr" />
  <img src="https://img.shields.io/badge/i18n-EN%20%7C%20JA-blue" />
  <img src="https://img.shields.io/badge/License-MIT-green" />
  <img src="https://img.shields.io/badge/Status-Production%20Ready-success" />
</p>

---

## ✨ Features

### ⚡ Lightning Payment Integration
- **Nostr Wallet Connect (NWC)** integration
- **Lightning Address** support
- **LNURL-pay** support with donation messages
- **Penalty Preset System** - Choose from 6 preset combinations:
  - ⚡ 15 seconds / 21 sats
  - 🔥 30 seconds / 42 sats
  - 💪 1 minute / 100 sats
  - 😴 5 minutes / 500 sats
  - 😱 10 minutes / 1,000 sats
  - 💀 15 minutes / 2,100 sats
  - ⚙️ Custom (set your own timeout and amount)
- **Configurable donation recipients**
  - Loaded from `assets/donation_recipients.yaml`
  - Default recipients include:
    - ZapClock Developer
    - Zeus Wallet Developer
    - Sparrow Wallet Developer
  - Add custom recipients via YAML or app settings
- Alarm continues ringing if payment fails (ensures you wake up!)

### 🟣 Nostr Integration (Planned)
- **Amber Signer** support for secure login
- **Donate to your Nostr follows** with Lightning Address
- **Identity-aware or anonymous** zaps
- Deep integration with the Nostr ecosystem

### ⏰ Powerful Alarm Features
- Precise alarm triggering at set times
- Recurring alarms (day of week specification)
  - Once only
  - Every day
  - Weekdays
  - Weekend
  - Custom (select specific days)
- Custom alarm sounds
- Vibration support
- Screen unlock functionality
- Full-screen alarm ring screen

### 🎨 Modern UI
- Material Design 3 compliant
- Dark theme support
- Bitcoin/Lightning-themed color palette
- Simple and intuitive interface
- Onboarding screen for first-time users

### 🌍 Internationalization
- Multi-language support (English and Japanese)
- Easy to add more languages via ARB files

---

## 🚀 How to Use

### Basic Alarm

1. Tap the "+" button on the alarm list screen
2. Set the time and label
3. Set repeat days (optional)
4. Select alarm sound (optional)
5. Tap "Save"
6. When the alarm rings, tap "Stop Alarm" to silence it

### Lightning Payment Required Alarm

#### Prerequisites
1. Prepare an NWC-compatible wallet ([Alby](https://getalby.com/), [Mutiny](https://mutinywallet.com/), etc.)
2. Obtain an NWC connection string

#### Setup Steps
1. **Configure NWC Connection**
   - Tap the ⚙️ (Settings) button in the top right
   - Enter the connection string in the "Nostr Wallet Connect" section
   - Test the connection with "Test Connection" (optional but recommended)
   
2. **Select Default Donation Recipient** (Optional)
   - In Settings, select a default recipient in the "Donation Recipient" section
   - Choose from:
     - ZapClock Developer (default)
     - Zeus Wallet Developer
     - Sparrow Wallet Developer
   - Or add custom recipients by editing `assets/donation_recipients.yaml`
   
3. **Create Penalty Alarm**
   - Tap "+" to create a new alarm
   - Set time and label as usual
   - In the "Penalty Settings" section:
     - Choose a preset (⚡ 15s/21 sats ~ 💀 15m/2,100 sats)
     - Or select "⚙️ Custom" to set your own timeout and amount
   - Optionally override the donation recipient for this specific alarm
   - Tap "Save"

#### Stopping the Alarm
1. Alarm rings at the set time
2. **If penalty is configured:**
   - Payment information is displayed (amount, timeout, recipient)
   - Countdown timer shows remaining time
   - **Option 1:** Tap "Stop now (no payment)" to silence the alarm
   - **Option 2:** Wait for timeout → Payment automatically sent via NWC
3. **If no penalty configured:**
   - Simply tap "Stop Alarm" to silence it

---

## 🛠️ Tech Stack

### Frontend
- **Flutter** 3.9.2+ - Cross-platform UI framework
- **Riverpod** 2.6.1 - State management
- **GoRouter** 14.6.4 - Routing
- **alarm** 5.1.5 - Alarm functionality
- **intl** 0.20.1 - Internationalization and date/time formatting
- **yaml** 3.1.2 - YAML parsing for donation recipients

### Backend (Rust)
- **nostr-sdk** 0.37 - Nostr client SDK (NWC, future: relay communication)
- **nwc** 0.37 - Nostr Wallet Connect
- **reqwest** 0.12 - HTTP client (rustls-tls, for LNURL-pay)
- **flutter_rust_bridge** 2.7.0 - Flutter-Rust bridge
- **tracing** 0.1 - Structured logging framework
- **tracing-subscriber** 0.3 - Log output configuration
- **tracing-android** 0.2 - Android Logcat integration

### Planned Dependencies
- **Amber SDK** - Nostr external signer integration
- Additional Nostr tools for identity and zap management

### Other
- **shared_preferences** 2.3.5 - Local storage
- **permission_handler** 11.3.1 - Permission management
- **http** 1.2.2 - HTTP client for Flutter

---

## 📦 Installation

### Development Environment Setup

#### Required Tools
- Flutter 3.9.2+ (FVM recommended)
- Rust 1.75+
- Android SDK
- cargo-ndk

```bash
# Install Flutter with FVM
fvm install 3.9.2
fvm use 3.9.2

# Install Rust tools
cargo install flutter_rust_bridge_codegen
cargo install cargo-ndk

# Install dependencies
fvm flutter pub get

# Optional: Customize donation recipients
# Edit assets/donation_recipients.yaml to add your own recipients
```

### Build

#### Debug Build
```bash
# Build Rust code (first time only)
cd rust
./build.sh

# Run Flutter app
cd ..
fvm flutter run
```

#### Release Build
```bash
# Build Rust library
cd rust
cargo ndk -t arm64-v8a -o ../android/app/src/main/jniLibs build --release
cargo ndk -t armeabi-v7a -o ../android/app/src/main/jniLibs build --release

# Build APK
cd ..
fvm flutter build apk --release
```

---

## 📱 Publishing on ZapStore

ZapClock is available (planned) on ZapStore, a Nostr-based app store.

### For Users
1. Install [ZapStore](https://zapstore.dev/)
2. Search for "ZapClock"
3. Tap the install button

### For Developers

We use GitHub Actions for automated releases:

- 🚀 **[Quick Start Guide](QUICKSTART_RELEASE.md)** - Get started in 15 minutes
- 🔧 **[Setup Guide](GITHUB_ACTIONS_SETUP.md)** - Detailed initial configuration
- 📖 **[Release Process](GITHUB_ACTIONS_RELEASE.md)** - Complete release workflow
- 📝 **[Manual Release](ZAPSTORE_RELEASE.md)** - Manual release instructions

#### Quick Release
```bash
# Update version in pubspec.yaml and zapstore.yaml
# Update CHANGELOG.md
git add .
git commit -m "chore: bump version to v1.0.1"
git tag v1.0.1
git push origin main v1.0.1
# GitHub Actions will automatically build and create a release
```

---

## 📂 Project Structure

```
zap_clock/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── app_theme.dart               # Theme configuration
│   ├── l10n/                        # Localization files
│   │   ├── app_en.arb               # English translations
│   │   ├── app_ja.arb               # Japanese translations
│   │   └── app_localizations*.dart  # Generated localization classes
│   ├── bridge_generated.dart/       # Generated Rust bridge code
│   │   ├── api.dart                 # Bridge API definitions
│   │   └── frb_generated*.dart      # FRB generated files
│   ├── models/
│   │   ├── alarm.dart               # Alarm data model
│   │   ├── donation_recipient.dart  # Donation recipient model
│   │   └── penalty_preset.dart      # Penalty preset model
│   ├── providers/
│   │   ├── alarm_provider.dart      # Alarm state management
│   │   ├── nwc_provider.dart        # NWC state management
│   │   └── storage_provider.dart    # Storage state management
│   ├── services/
│   │   ├── alarm_service.dart       # Alarm control
│   │   ├── storage_service.dart     # Local storage
│   │   ├── nwc_service.dart         # NWC/Lightning payment
│   │   ├── permission_service.dart  # Permission management
│   │   └── ringtone_service.dart    # Custom ringtone handling
│   ├── screens/
│   │   ├── alarm_list_screen.dart   # Alarm list
│   │   ├── alarm_edit_screen.dart   # Alarm editing
│   │   ├── alarm_ring_screen.dart   # Alarm ringing
│   │   ├── settings_screen.dart     # Settings
│   │   └── onboarding_screen.dart   # Onboarding
│   └── widgets/                     # Common widgets
├── rust/
│   ├── Cargo.toml                   # Rust dependencies
│   ├── build.sh                     # Build script
│   └── src/
│       ├── lib.rs                   # Library entry
│       ├── api.rs                   # Flutter public API
│       ├── nwc.rs                   # NWC client
│       └── lightning.rs             # Lightning payment processing
├── android/                         # Android-specific config
├── assets/
│   ├── alarm_sound.mp3              # Default alarm sound
│   ├── icon.png                     # App icon
│   └── donation_recipients.yaml     # Donation recipient list
├── screenshots/                     # Screenshots for ZapStore
├── zapstore.yaml                    # ZapStore manifest
├── ZAPSTORE_RELEASE.md              # ZapStore release guide
├── IMPLEMENTATION_STATUS.md         # Implementation status
├── PHASE2_IMPLEMENTATION.md         # Phase 2 implementation details
├── CHANGELOG.md                     # Version history
└── l10n.yaml                        # Localization configuration
```

---

## 🧪 Testing

```bash
# Unit tests
fvm flutter test

# Integration tests
fvm flutter test integration_test/
```

---

## 🔍 Debugging & Logging

### Rust Log Level Configuration

The Rust backend uses the `tracing` framework for structured logging. You can control log levels using the `RUST_LOG` environment variable.

#### Log Levels
- `error` - Only error messages
- `warn` - Warnings and errors
- `info` - Informational messages (default)
- `debug` - Debug messages
- `trace` - Detailed trace information

#### Setting Log Levels

**All modules at debug level:**
```bash
RUST_LOG=debug fvm flutter run
```

**App-specific trace level:**
```bash
RUST_LOG=zap_clock=trace fvm flutter run
```

**Multiple module configuration:**
```bash
RUST_LOG=zap_clock=trace,nostr_sdk=info,nwc=debug fvm flutter run
```

**For Android builds:**
```bash
# Debug build with verbose logging
RUST_LOG=trace fvm flutter build apk --debug

# View logs in logcat
adb logcat | grep zap_clock
```

#### Log Output Details

The logging system provides:
- ✅ Structured log output (JSON format support)
- ✅ Timestamp with microsecond precision
- ✅ Module/target information
- ✅ Thread ID and name
- ✅ File name and line number
- ✅ Color-coded output (non-Android)
- ✅ Android Logcat integration
- ✅ Performance tracing support

#### Example Output

```
2024-10-28T10:30:45.123456Z INFO zap_clock::nwc: NWC client initialized connection_string="nostr+walletconnect://..."
2024-10-28T10:30:45.234567Z DEBUG zap_clock::lightning: Resolving Lightning address lightning_address="user@getalby.com"
2024-10-28T10:30:46.345678Z TRACE zap_clock::lightning: Fetching invoice amount_sats=1000
```

---

## 🎉 Production Ready

ZapClock v1.0.0 is now production-ready with all core features fully implemented and tested!

**This is the first public release available on ZapStore!**

### What's Working
- ✅ Alarm functionality with precise timing
- ✅ Lightning payments via NWC
- ✅ Penalty Preset System (6 presets + custom)
- ✅ Multi-language support (English & Japanese)
- ✅ YAML-based donation recipient configuration
- ✅ Custom ringtone support
- ✅ Permission management system
- ✅ Full-screen alarm ring screen
- ✅ Screenshots captured for ZapStore

### Future Enhancements
See the [Roadmap](#-roadmap) section below for planned features including:
- Amber (Nostr Signer) integration
- Nostr follow-based donation
- Payment history and analytics
- iOS support

For complete implementation details, refer to:
- [`IMPLEMENTATION_STATUS.md`](IMPLEMENTATION_STATUS.md) - Current status
- [`PHASE2_IMPLEMENTATION.md`](PHASE2_IMPLEMENTATION.md) - Phase 2 details
- [`CHANGELOG.md`](CHANGELOG.md) - Version history

---

## 🗺️ Roadmap

### Phase 1: Basic Alarm App ✅ (Completed)
- [x] Alarm setup and management
- [x] Alarm ringing and stopping
- [x] Local data persistence
- [x] Material Design UI
- [x] Recurring alarms with flexible scheduling
- [x] Custom alarm sounds
- [x] Full-screen alarm ring screen
- [x] Onboarding screen

### Phase 2: Lightning Payment Feature ✅ (Completed)
- [x] NWC integration
- [x] Lightning Address support
- [x] Settings screen with NWC configuration
- [x] Payment UI with loading states
- [x] Donation recipient selection
- [x] **Penalty Preset System** (6 presets + custom)
- [x] YAML-based donation recipient configuration
- [x] Per-alarm donation recipient override
- [x] **Internationalization** (English and Japanese)
- [x] Permission management system
- [x] Custom ringtone support

### Phase 3: Production Release & Testing ✅ (Completed)
- [x] Screenshots captured for ZapStore
- [x] Production build optimization
- [x] Enhanced error handling and logging
- [x] Permission management system
- [x] Documentation updates
- [x] Ready for ZapStore release

### Phase 4: Nostr Integration Enhancement (Planned)
- [ ] **Amber (Nostr Signer) Integration**
  - Login with any Nostr account using Amber
  - Secure key management through external signer
- [ ] **Nostr Follow-based Donation**
  - Select donation recipients from your Nostr follows
  - Filter follows by Lightning Address availability
  - Random or manual selection from followed accounts
- [ ] **Identity-aware Zaps**
  - Choose between Nostr-identity zaps or anonymous zaps
  - Add NIP-57 zap receipt support
  - Display zap messages in payment UI
- [ ] Payment history display
- [ ] Multiple NWC connection profile management

### Phase 5: Advanced Features (Future)
- [ ] Biometric authentication for payments
- [ ] Payment amount limit settings
- [ ] Alarm statistics and analytics
- [ ] Widget support
- [ ] iOS support
- [ ] Additional language support

### Phase 6: ZapStore Release & Growth 🚀 (Ready to Launch!)
- [x] Screenshots prepared
- [x] Metadata updated (zapstore.yaml)
- [x] Documentation complete
- [ ] Community feedback and iteration
- [ ] Marketing and user acquisition

---

## 🤝 Contributing

Pull requests are welcome! For major changes, please open an issue first to discuss what you would like to change.

### Development Flow
1. Fork this repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Create a pull request

---

## 📄 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

This project is built upon the following open-source projects:

- [Flutter](https://flutter.dev/)
- [Rust](https://www.rust-lang.org/)
- [Nostr](https://nostr.com/)
- [flutter_rust_bridge](https://github.com/fzyzcjy/flutter_rust_bridge)
- [alarm package](https://pub.dev/packages/alarm)

---

## 📞 Contact

- **GitHub Issues**: [Report a bug or request a feature](https://github.com/higedamc/zap_clock/issues)
- **Email**: kohei.o@proton.me
- **Nostr**: `npub1ckhkmr84j33580dgwns9l6e4gpc5kfzjaq05ekarpxjgf5dgj76qmmwyea`
- **Developer Nostr**: `npub16lrdq99ng2q4hg5ufre5f8j0qpealp8544vq4ctn2wqyrf4tk6uqn8mfeq`
- **Lightning**: `godzhigella@getalby.com` (Support the developer!)

---

## ⚡ Let's Zap! ⚡

Wake up reliably every morning with ZapClock! 🌅

**A practical alarm app contributing to the Bitcoin/Nostr ecosystem.**

---

<p align="center">
  Made with ⚡ and ❤️ by the ZapClock Team
</p>
