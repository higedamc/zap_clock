# ZapStore Release Guide ⚡

This document explains the procedure for publishing ZapClock on ZapStore.

## 📋 Prerequisites

### 1. Prepare Nostr Account

- **Nostr private/public keys**: Used as developer account
- **Recommended clients**: 
  - [Alby](https://getalby.com/) - Browser extension
  - [Damus](https://damus.io/) - iOS
  - [Amethyst](https://github.com/vitorpamplona/amethyst) - Android

### 2. Required Tools

```bash
# flutter_rust_bridge_codegen
cargo install flutter_rust_bridge_codegen

# cargo-ndk (for Rust build on Android)
cargo install cargo-ndk

# ZapStore CLI (may be needed in the future)
# npm install -g @zapstore/cli
```

---

## 🚀 Release Procedure

### Step 1: Build the Application

#### 1.1 Build Rust Code

```bash
cd /Users/apple/work/zap_clock/rust

# Build for Android
cargo ndk -t arm64-v8a -o ../android/app/src/main/jniLibs build --release
cargo ndk -t armeabi-v7a -o ../android/app/src/main/jniLibs build --release
cargo ndk -t x86_64 -o ../android/app/src/main/jniLibs build --release
```

#### 1.2 Build Flutter APK

```bash
cd /Users/apple/work/zap_clock

# Release build
fvm flutter build apk --release

# Or optimize size with split-per-abi
fvm flutter build apk --release --split-per-abi
```

The built APK will be located at:
```
build/app/outputs/flutter-apk/app-release.apk
```

#### 1.3 Get APK Hash Value

```bash
# Calculate SHA256 hash
sha256sum build/app/outputs/flutter-apk/app-release.apk

# Or
openssl dgst -sha256 build/app/outputs/flutter-apk/app-release.apk
```

Record this hash value in `zapstore.yaml`.

---

### Step 2: Prepare Screenshots

Take screenshots and place them in the `screenshots/` directory.

For details, refer to [`screenshots/README.md`](screenshots/README.md).

Required screenshots:
- ✅ `01_alarm_list.png` - Alarm list
- ✅ `02_alarm_edit.png` - Alarm editing
- ✅ `03_alarm_ring.png` - Alarm ringing
- ✅ `04_settings.png` - Settings screen

---

### Step 3: Update `zapstore.yaml`

Open the `zapstore.yaml` file and update the following items:

```yaml
# Developer information
developer:
  name: "Your Name"
  pubkey: "npub1..." # or "hex..."
  email: "your@email.com" # Optional
  website: "https://your-website.com" # Optional

# Source code (optional but recommended)
source:
  repository: "https://github.com/yourusername/zap_clock"
  license: "MIT"

# Platform information
platforms:
  android:
    minSdkVersion: 23
    targetSdkVersion: 34
    apk: "build/app/outputs/flutter-apk/app-release.apk"
    apkHash: "Put SHA256 hash here"
```

---

### Step 4: Publish to ZapStore

#### 4.1 Access ZapStore Website

1. Access [ZapStore](https://zapstore.dev/)
2. Log in with Nostr extension (Alby, etc.)

#### 4.2 Register App

Follow ZapStore's instructions to:

1. **Enter App Information**
   - Refer to `zapstore.yaml` content
   - Name, description, category, etc.

2. **Upload APK**
   - Upload `build/app/outputs/flutter-apk/app-release.apk`
   - Or specify external URL (GitHub Releases, etc.)

3. **Verify Metadata**
   - Screenshots
   - Icon
   - Description

4. **Publish Nostr Event**
   - ZapStore creates NIP-89 (Application Handler) event
   - Published as kind: 32267 event

---

### Step 5: Post-Publication Verification

#### 5.1 Verify in ZapStore App

1. Download ZapStore app (Android)
2. Search for app: "ZapClock"
3. Install and verify operation

#### 5.2 Verify Nostr Event

Verify the published event in Nostr client (Amethyst, etc.):

```
kind: 32267
tags: [
  ["d", "com.zapclock.zap_clock"],
  ["name", "ZapClock"],
  ["picture", "..."],
  ["about", "..."],
  ...
]
```

---

## 🔄 Update Procedure

### When Updating Version

1. **Update Version Number**
   - `pubspec.yaml`: `version: 1.0.1+2`
   - `zapstore.yaml`: `version: "1.0.1"`, `versionCode: 2`

2. **Add Changelog**
   Update `changelog` section in `zapstore.yaml`:
   ```yaml
   changelog: |
     ## v1.0.1
     - 🐛 Bug fixes
     - ✨ New features added
     
     ## v1.0.0 (Initial Release)
     - ⚡ Lightning payment to stop alarm feature
     ...
   ```

3. **Rebuild and Upload APK**
   - Repeat steps 1-2 above
   - Update new APK hash

4. **Publish Update on ZapStore**
   - Select "Update" in ZapStore dashboard
   - Upload new APK and metadata

---

## 📝 Checklist

Verify the following before release:

### Build
- [ ] Rust code builds without errors
- [ ] Flutter APK builds in release mode
- [ ] APK size is appropriate (guideline: < 50MB)
- [ ] All architectures (arm64-v8a, armeabi-v7a) are built

### Metadata
- [ ] All fields in `zapstore.yaml` are filled in
- [ ] App name and description are accurate
- [ ] Developer information (Nostr public key) is set
- [ ] 4 or more screenshots prepared
- [ ] Icon is high resolution (512x512 or higher recommended)

### Testing
- [ ] Verified operation on device/emulator
- [ ] Alarm functionality works properly
- [ ] Lightning payment functionality works (NWC connection test)
- [ ] Permissions (notification, alarm, internet) are correctly requested
- [ ] App doesn't crash

### Security
- [ ] APK is signed
- [ ] Personal information is not hardcoded
- [ ] NWC connection string is encrypted (future task)

### Documentation
- [ ] README.md is updated
- [ ] Privacy policy is specified
- [ ] Source code is published (recommended)

---

## 🐛 Troubleshooting

### APK Build Error

**Problem**: Rust library not linked

**Solution**:
```bash
# Check jniLibs directory
ls -la android/app/src/main/jniLibs/

# Rebuild if necessary
cd rust
./build.sh
```

### App Not Found in ZapStore

**Cause**:
- Nostr event not propagated to relay
- Duplicate `identifier`
- Incomplete metadata

**Solution**:
- Use multiple Nostr relays
- Make `identifier` in `zapstore.yaml` unique
- Contact ZapStore support

### App Won't Launch After Installation

**Cause**:
- Required permissions not declared
- Rust library not built correctly

**Solution**:
- Verify permissions in `AndroidManifest.xml`
- Check error logs with `adb logcat`
- Rebuild Rust code

---

## 📚 Reference Links

### ZapStore Related
- [ZapStore Official Site](https://zapstore.dev/)
- [ZapStore GitHub](https://github.com/zapstore)
- [NIP-89 Specification](https://github.com/nostr-protocol/nips/blob/master/89.md)

### Nostr Related
- [Nostr Official Site](https://nostr.com/)
- [NIPs (Nostr Implementation Possibilities)](https://github.com/nostr-protocol/nips)
- [Awesome Nostr](https://github.com/aljazceru/awesome-nostr)

### Development Tools
- [flutter_rust_bridge](https://github.com/fzyzcjy/flutter_rust_bridge)
- [cargo-ndk](https://github.com/bbqsrc/cargo-ndk)

---

## 💡 Tips

### To Succeed in Release

1. **Publish Source Code**
   - Publish repository on GitHub
   - Open source is well-received in Nostr community

2. **Promote on Nostr**
   - Post app release on Nostr
   - Hashtags: `#zapstore #bitcoin #lightning #nostr`

3. **Accept Feedback**
   - Enable GitHub Issues
   - Accept questions and bug reports on Nostr

4. **Continuous Improvement**
   - Reflect user feedback
   - Regular updates

---

## ⚡ Let's Deliver ZapClock to the World!

Follow this guide to publish ZapClock on ZapStore.
We hope it becomes a wonderful app contributing to the Bitcoin/Nostr ecosystem!

**Good luck! 🚀⚡**
