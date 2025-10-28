# Changelog

All notable changes to ZapClock will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned
- Rust bridge generation and device testing
- Amber (Nostr Signer) integration
- Nostr follow-based donation
- Identity-aware zaps (NIP-57)
- Payment history display
- Multiple NWC connection profile management
- Biometric authentication for payments

---

## [1.0.0] - 2025-10-28

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

### Phase 3: Nostr Integration Enhancement (Planned)
- [ ] Rust bridge generation
- [ ] Amber integration
- [ ] Nostr follow-based donation
- [ ] Identity-aware zaps
- [ ] Payment history

### Phase 4: ZapStore Release (Planned)
- [ ] Screenshot capture
- [ ] Metadata preparation
- [ ] Publish to ZapStore

---

[Unreleased]: https://github.com/yourusername/zap_clock/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/yourusername/zap_clock/releases/tag/v1.0.0

