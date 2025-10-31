# Changelog

All notable changes to ZapClock will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned
- Amber (Nostr Signer) integration
- Nostr follow-based donation (random selection from your follows)
- Identity-aware zaps (NIP-57)
- Payment history display
- Multiple NWC connection profile management
- Biometric authentication for payments
- iOS support

---

## [1.0.0] - 2025-10-31

🎉 **First Public Release!** 🎉

This is the first public release of ZapClock, available on ZapStore!

### Added
- ⚡ **Penalty Preset System**
  - 6 smart presets for penalty amounts and timeouts:
    - ⚡ 15 seconds / 21 sats
    - 🔥 30 seconds / 42 sats
    - 💪 1 minute / 100 sats
    - 😴 5 minutes / 500 sats
    - 😱 10 minutes / 1,000 sats
    - 💀 15 minutes / 2,100 sats
  - ⚙️ Custom preset option (set your own timeout and amount)
  - Intuitive UI with emoji-based preset selection

- 🌍 **Internationalization (i18n)**
  - Multi-language support system
  - English (en) translations
  - Japanese (ja) translations
  - ARB file-based localization
  - Easy to add more languages

- 🎁 **Donation Recipient Management**
  - YAML-based recipient configuration (`assets/donation_recipients.yaml`)
  - 3 default preset recipients:
    - ZapClock Developer
    - Zeus Wallet Developer
    - Sparrow Wallet Developer
  - Per-alarm donation recipient override
  - Easy to add custom recipients

- 💬 **Payment Message Feature**
  - Automatic message attachment to Lightning payments
  - "donation from ZapClock" message sent with each payment
  - LNURL-pay comment parameter support

- 🎵 **Custom Ringtone Support**
  - System ringtone picker integration
  - Custom alarm sounds per alarm
  - Ringtone service for media handling

- 🔐 **Permission Management System**
  - Comprehensive permission handling
  - Runtime permission requests
  - User-friendly permission explanations

- 📸 **App Screenshots**
  - Added screenshots for ZapStore listing
  - Screenshots for main screens (alarm list, edit, ring, settings)

### Changed
- Updated zapstore.yaml with latest feature descriptions
- Improved zapstore.yaml tags (added i18n, lnurl, rust, flutter, donation)
- Enhanced app description to highlight new features
- Improved UI/UX for alarm editing with penalty settings

### Technical
- Enhanced Rust backend logging with tracing framework
- Improved error handling in Lightning payment flow
- Optimized build configuration for ProGuard
- Updated dependencies (rust/Cargo.toml, pubspec.yaml)
- Better integration between Flutter and Rust via flutter_rust_bridge

### Fixed
- Improved alarm reliability on various Android versions
- Better handling of network errors during Lightning payments
- Enhanced permission request flow

---

## [0.9.0] - 2025-10-28

**Development Release** - Internal testing version

### Added
- ⚡ **Lightning Payment Feature**
  - Nostr Wallet Connect (NWC) integration
  - Lightning Address support
  - LNURL-pay implementation
  - Donation recipient selection (5 preset recipients)
  - Payment UI with loading states and error handling
  
- ⏰ **Alarm Features**
  - Precise alarm triggering at set times
  - Recurring alarms (day of week specification)
  - Custom alarm sounds
  - Vibration support
  - Screen unlock functionality when alarm rings
  - Full-screen alarm ring screen
  
- 🎨 **UI/UX**
  - Material Design 3 compliant
  - Dark theme support
  - Bitcoin/Lightning-themed color palette
  - Simple and intuitive interface
  - Onboarding screen for first-time users
  
- ⚙️ **Settings**
  - NWC connection string configuration
  - Connection test functionality
  - Donation recipient selection
  - Alarm sound selection
  - Vibration toggle
  
- 📱 **Platform Support**
  - Android 6.0+ (API 23+)
  - Material You dynamic color support (Android 12+)
  - Adaptive icons
  
- 🔒 **Permissions**
  - Exact alarm scheduling
  - Notification support
  - Wake lock
  - Full screen intent
  - Internet access for Lightning payments
  
- 📚 **Documentation**
  - Comprehensive README
  - ZapStore release guide
  - GitHub Actions automated release workflow
  - Implementation status documentation

### Technical
- Flutter 3.9.2+ framework
- Rust backend with nostr-sdk and nwc crates
- flutter_rust_bridge for Dart-Rust interop
- Riverpod 2.6.1 for state management
- GoRouter 14.6.4 for navigation
- Local storage with shared_preferences

### Known Issues
- Rust bridge not yet generated for production builds
- Lightning payment uses mock implementation in development
- Screenshots not yet captured for ZapStore

---

## Development Phases

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
- [x] **Penalty Preset System** (6 presets + custom)
- [x] YAML-based donation recipient configuration
- [x] Per-alarm donation recipient override
- [x] **Internationalization** (English and Japanese)
- [x] Permission management system
- [x] Custom ringtone support
- [x] Payment message feature ("donation from ZapClock")

### Phase 3: Nostr Integration Enhancement (Planned)
- [ ] **Amber (Nostr Signer)** integration for secure login
- [ ] **Nostr follow-based donation** - select recipients from your follows
- [ ] Random selection from followed accounts
- [ ] Identity-aware or anonymous zaps (NIP-57)
- [ ] Payment history display
- [ ] Multiple NWC connection profile management

