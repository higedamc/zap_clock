# ZapClock ⚡⏰

**An Alarm App That Stops with Lightning Payments**

ZapClock is a funny alarm app powered by the Bitcoin Lightning Network. The alarm stops only after you send a specified amount via Lightning. With the compelling force of "pay to wake up," you'll never oversleep again!

<br>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.9.2-02569B?logo=flutter" />
  <img src="https://img.shields.io/badge/Rust-1.75-orange?logo=rust" />
  <img src="https://img.shields.io/badge/Lightning-Enabled-yellow?logo=lightning" />
  <img src="https://img.shields.io/badge/Nostr-NWC-purple?logo=nostr" />
  <img src="https://img.shields.io/badge/License-MIT-green" />
</p>

---

## ✨ Features

### ⚡ Lightning Payment Integration
- **Nostr Wallet Connect (NWC)** integration
- **Lightning Address** support
- **LNURL-pay** support with donation messages
- **Multiple donation recipients to choose from**
  - Human Rights Foundation
  - Zeus Lightning Wallet developer
  - Sparrow Wallet developer
  - OpenSats
  - Bitcoin Design Community
- Alarm continues ringing if payment fails (ensures you wake up!)

### 🟣 Nostr Integration (Coming Soon)
- **Amber Signer** support for secure login
- **Donate to your Nostr follows** with Lightning Address
- **Identity-aware or anonymous** zaps
- Deep integration with the Nostr ecosystem

### ⏰ Powerful Alarm Features
- Precise alarm triggering at set times
- Recurring alarms (day of week specification)
- Custom alarm sounds
- Vibration support
- Screen unlock functionality

### 🎨 Modern UI
- Material Design 3 compliant
- Dark theme support
- Bitcoin/Lightning-themed color palette
- Simple and intuitive interface

---

## 🚀 How to Use

### Basic Alarm

1. Tap the "+" button on the alarm list screen
2. Set the time and label
3. Tap "Save"
4. When the alarm rings, tap "Stop Alarm" to silence it

### Lightning Payment Required Alarm

#### Prerequisites
1. Prepare an NWC-compatible wallet ([Alby](https://getalby.com/), [Mutiny](https://mutinywallet.com/), etc.)
2. Obtain an NWC connection string

#### Setup Steps
1. Tap the ⚙️ (Settings) button in the top right
2. Enter the connection string in the "Nostr Wallet Connect" section
3. Test the connection with "Test Connection" (optional)
4. Select a recipient in the "Donation Recipient" section
   - Human Rights Foundation (default)
   - Zeus Lightning Wallet developer
   - Sparrow Wallet developer
   - OpenSats
   - Bitcoin Design Community
5. Enter Lightning settings in the alarm edit screen
   - Amount (sats)
   - Timeout duration
6. Tap "Save"

#### Stopping the Alarm
1. Alarm rings
2. Payment information is displayed
3. Tap "Pay to Stop Alarm" button
4. Processing payment... (loading indicator)
5. ✅ Payment successful → Alarm stops
6. ❌ Payment failed → Error message, alarm continues ringing

---

## 🛠️ Tech Stack

### Frontend
- **Flutter** 3.9.2+ - Cross-platform UI framework
- **Riverpod** 2.6.1 - State management
- **GoRouter** 14.6.4 - Routing
- **alarm** 5.1.5 - Alarm functionality

### Backend (Rust)
- **nostr-sdk** 0.37 - Nostr client SDK (NWC, future: relay communication)
- **nwc** 0.37 - Nostr Wallet Connect
- **reqwest** 0.12 - HTTP client (for LNURL-pay)
- **flutter_rust_bridge** 2.11.1 - Flutter-Rust bridge

### Planned Dependencies
- **Amber SDK** - Nostr external signer integration
- Additional Nostr tools for identity and zap management

### Other
- **shared_preferences** - Local storage
- **permission_handler** - Permission management

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
│   ├── models/
│   │   ├── alarm.dart               # Alarm data model
│   │   └── donation_recipient.dart  # Donation recipient presets
│   ├── providers/
│   │   ├── alarm_provider.dart      # Alarm state management
│   │   └── nwc_provider.dart        # NWC state management
│   ├── services/
│   │   ├── alarm_service.dart       # Alarm control
│   │   ├── storage_service.dart     # Local storage
│   │   └── nwc_service.dart         # NWC/Lightning payment
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
│   └── alarm_sound.mp3              # Alarm sound
├── screenshots/                     # Screenshots for ZapStore
├── zapstore.yaml                    # ZapStore manifest
├── ZAPSTORE_RELEASE.md              # ZapStore release guide
├── IMPLEMENTATION_STATUS.md         # Implementation status
└── PHASE2_IMPLEMENTATION.md         # Phase 2 implementation details
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

## 🐛 Known Issues

- Currently, the Rust bridge has not been generated, so Lightning payment functionality operates with mock implementation
- To use in production, Rust code must be built

For details, refer to [`PHASE2_IMPLEMENTATION.md`](PHASE2_IMPLEMENTATION.md).

---

## 🗺️ Roadmap

### Phase 1: Basic Alarm App ✅
- [x] Alarm setup and management
- [x] Alarm ringing and stopping
- [x] Local data persistence
- [x] Material Design UI

### Phase 2: Lightning Payment Feature ✅
- [x] NWC integration
- [x] Lightning Address support
- [x] Settings screen
- [x] Payment UI
- [x] Donation recipient selection

### Phase 3: Nostr Integration Enhancement (Planned)
- [ ] Rust bridge generation and device testing
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
- [ ] Biometric authentication for payments
- [ ] Payment amount limit settings

### Phase 4: ZapStore Release (Planned)
- [ ] Screenshot capture
- [ ] Metadata preparation
- [ ] Publish to ZapStore

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

- **GitHub Issues**: [Report a bug or request a feature](https://github.com/yourusername/zap_clock/issues)
- **Nostr**: `npub1...` (Your Nostr public key)
- **Lightning**: `yourname@getalby.com` (Lightning Address)

---

## ⚡ Let's Zap! ⚡

Wake up reliably every morning with ZapClock! 🌅

**A practical alarm app contributing to the Bitcoin/Nostr ecosystem.**

---

<p align="center">
  Made with ⚡ and ❤️ by the ZapClock Team
</p>
