# ZapStore Release Checklist ✅

This checklist outlines the items to verify before publishing ZapClock on ZapStore.

---

## 📝 Preparation

### Nostr Account
- [ ] Nostr private/public keys obtained
- [ ] Nostr client (Alby, Damus, Amethyst, etc.) set up
- [ ] Public key (npub or hex) verified

### Development Tools
- [ ] `flutter_rust_bridge_codegen` installed
- [ ] `cargo-ndk` installed
- [ ] Android SDK set up
- [ ] FVM or Flutter 3.9.2+ installed

---

## 🔧 Code Preparation

### Update zapstore.yaml
- [ ] Enter developer name in `developer.name`
- [ ] Enter Nostr public key (npub or hex) in `developer.pubkey`
- [ ] Enter email address in `developer.email` (optional)
- [ ] Enter website URL in `developer.website` (optional)
- [ ] Enter GitHub repository URL in `source.repository` (recommended)
- [ ] Enter "MIT" in `source.license` (or change)
- [ ] Verify and update `description.short` and `description.full`
- [ ] Verify and update `changelog`

### Build the App
- [ ] Rust code builds without errors
  ```bash
  cd rust
  cargo build --release
  ```
- [ ] Build Rust library for Android
  ```bash
  cargo ndk -t arm64-v8a -o ../android/app/src/main/jniLibs build --release
  cargo ndk -t armeabi-v7a -o ../android/app/src/main/jniLibs build --release
  ```
- [ ] Build Flutter APK in release mode
  ```bash
  cd ..
  fvm flutter build apk --release
  ```
- [ ] APK size is appropriate (guideline: < 50MB)
- [ ] Calculate SHA256 hash of APK
  ```bash
  sha256sum build/app/outputs/flutter-apk/app-release.apk
  ```
- [ ] Update `platforms.android.apk` and `apkHash` in `zapstore.yaml`

### Testing
- [ ] App launches on device/emulator
- [ ] Alarm functionality works properly
  - [ ] Create alarm
  - [ ] Edit alarm
  - [ ] Delete alarm
  - [ ] Alarm ringing
  - [ ] Stop alarm
- [ ] Recurring alarms work
- [ ] Lightning payment functionality works (NWC connection test)
  - [ ] Enter NWC connection string
  - [ ] Connection test succeeds
  - [ ] Execute Lightning payment (test environment)
- [ ] Permissions are correctly requested
  - [ ] Notification permission
  - [ ] Alarm permission
  - [ ] Internet permission
- [ ] App doesn't crash
- [ ] No memory leaks

---

## 🎨 Metadata Preparation

### Screenshots
- [ ] Capture alarm list screen screenshot
  - Filename: `screenshots/01_alarm_list.png`
  - Resolution: 1080x2400px recommended
- [ ] Capture alarm edit screen screenshot
  - Filename: `screenshots/02_alarm_edit.png`
- [ ] Capture alarm ringing screen screenshot
  - Filename: `screenshots/03_alarm_ring.png`
- [ ] Capture settings screen screenshot
  - Filename: `screenshots/04_settings.png`
- [ ] Verify screenshots don't contain personal information
- [ ] Verify screenshots are clear and visible

### Icon
- [ ] App icon is high resolution (512x512px or higher recommended)
- [ ] Icon fits Bitcoin/Lightning theme
- [ ] `icon` path in `zapstore.yaml` is correct

---

## 🔒 Security

- [ ] APK is signed
- [ ] Personal information is not hardcoded
- [ ] API keys or private keys are not included in code
- [ ] NWC connection string is stored locally only
- [ ] Sensitive files added to `.gitignore`

---

## 📚 Documentation

- [ ] README.md updated with latest information
- [ ] ZAPSTORE_RELEASE.md is readable
- [ ] LICENSE file exists
- [ ] Privacy policy stated in `zapstore.yaml`
- [ ] Changelog updated

---

## 🚀 ZapStore Publication

### ZapStore Website
- [ ] Access [ZapStore](https://zapstore.dev/)
- [ ] Log in with Nostr extension (Alby, etc.)
- [ ] Create new application

### Enter App Information
- [ ] App name: "ZapClock"
- [ ] App ID: "com.zapclock.zap_clock"
- [ ] Category: "Utilities"
- [ ] Enter description (from `zapstore.yaml`)
- [ ] Set tags (bitcoin, lightning, nostr, alarm)

### Upload Files
- [ ] Upload APK file
  - Path: `build/app/outputs/flutter-apk/app-release.apk`
- [ ] Upload screenshots (4 images)
- [ ] Upload app icon

### Verify Metadata
- [ ] Verify all information is correctly entered
- [ ] Verify screenshots display in correct order
- [ ] Verify in preview screen

### Publish
- [ ] Click "Publish" button
- [ ] Verify Nostr event created
- [ ] Verify event kind: 32267 published

---

## 🧪 Post-Publication Verification

### Verify in ZapStore App
- [ ] Search "ZapClock" in ZapStore app (Android)
- [ ] App detail page displays correctly
- [ ] Screenshots display
- [ ] Description displays correctly
- [ ] "Install" button functions

### Installation Test
- [ ] Install app from ZapStore
- [ ] App launches properly
- [ ] All features work

### Verify Nostr Event
- [ ] Verify event in Nostr client (Amethyst, etc.)
- [ ] kind: 32267 event published correctly
- [ ] Metadata is correct

---

## 📣 Promotion (Optional)

### SNS Posts
- [ ] Post publication on Nostr
  - Hashtags: `#zapstore #bitcoin #lightning #nostr #alarm`
  - Link: ZapStore app page
- [ ] Post on Twitter (optional)
- [ ] Post on Reddit (r/Bitcoin, r/lightningnetwork, etc.) (optional)

### Community
- [ ] Share in Nostr Telegram group (optional)
- [ ] Post on BitcoinTalk forum (optional)
- [ ] Post on Product Hunt (optional)

---

## 🔄 Update Preparation (For Future)

### Version Management
- [ ] Update version number in `pubspec.yaml`
- [ ] Update version number and versionCode in `zapstore.yaml`
- [ ] Update changelog

### Continuous Improvement
- [ ] Enable GitHub Issues
- [ ] Collect user feedback
- [ ] Plan bug fixes and feature additions

---

## 📝 Notes Section

### Troubleshooting
- Record problems here if any:
  ```
  [Date] [Problem description]
  Solution: [Solution method]
  ```

### Contacts
- ZapStore support: (fill in if needed)
- Community: (fill in if needed)

---

## ✅ Final Verification

- [ ] All checklist items completed
- [ ] App published on ZapStore
- [ ] Installed and tested
- [ ] Documentation up to date

---

**🎉 Congratulations! ZapClock is now published on ZapStore!**

---

_Created: 2025-01-25_
_Last updated: 2025-01-25_
