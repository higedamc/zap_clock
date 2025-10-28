# GitHub Actions を使った ZapStore 自動リリース ⚡🚀

このドキュメントでは、GitHub Actions を使用して ZapClock を ZapStore に自動リリースする手順を説明します。

---

## 📋 目次

1. [概要](#概要)
2. [前提条件](#前提条件)
3. [リリースフロー](#リリースフロー)
4. [セットアップ手順](#セットアップ手順)
5. [GitHub Actions ワークフロー](#github-actions-ワークフロー)
6. [リリース手順](#リリース手順)
7. [トラブルシューティング](#トラブルシューティング)

---

## 🎯 概要

### リリースプロセス

```
1. バージョンタグをプッシュ (例: v1.0.0)
   ↓
2. GitHub Actions が自動実行
   ↓
3. Rust ライブラリをビルド (arm64-v8a, armeabi-v7a, x86_64)
   ↓
4. Flutter APK をビルド (release モード)
   ↓
5. APK に署名
   ↓
6. GitHub Releases に APK をアップロード
   ↓
7. zapstore.yaml を更新 (APK ハッシュ)
   ↓
8. (手動) Nostr イベント発行で ZapStore に通知
```

### 利点

- ✅ **完全自動化**: タグをプッシュするだけでリリース
- ✅ **再現性**: 毎回同じ環境でビルド
- ✅ **透明性**: ビルドログが公開される
- ✅ **効率性**: 複数アーキテクチャを並列ビルド
- ✅ **安全性**: GitHub Secrets で署名鍵を管理

---

## 📝 前提条件

### 1. Nostr アカウント

- Nostr 秘密鍵/公開鍵を取得済み
- Nostr クライアント (Alby, Amethyst など) をセットアップ済み

### 2. Android 署名鍵

APK に署名するためのキーストアファイルが必要です。

#### キーストアの作成

```bash
keytool -genkey -v \
  -keystore upload-keystore.jks \
  -alias upload \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -storepass "your_keystore_password" \
  -keypass "your_key_password"
```

**⚠️ 重要**: このファイルは絶対に Git にコミットしないでください！

#### キーストアのエンコード

GitHub Secrets に保存するため、Base64 エンコードします：

```bash
base64 -i upload-keystore.jks | pbcopy  # macOS
# または
base64 upload-keystore.jks > keystore.b64  # Linux/Windows
```

---

## 🔄 リリースフロー

### アーキテクチャ

```
┌─────────────────────────────────────────────────────────┐
│  開発者ローカル環境                                       │
│  $ git tag v1.0.0                                       │
│  $ git push origin v1.0.0                               │
└─────────────────┬───────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────┐
│  GitHub Actions (Ubuntu Runner)                         │
│                                                           │
│  ┌─────────────────────────────────────────────┐        │
│  │ Job 1: Build Rust Libraries                 │        │
│  │  - Setup Rust toolchain                     │        │
│  │  - Install cargo-ndk                        │        │
│  │  - Build for arm64-v8a                      │        │
│  │  - Build for armeabi-v7a                    │        │
│  │  - Build for x86_64                         │        │
│  │  - Upload artifacts                         │        │
│  └─────────────────────────────────────────────┘        │
│                  │                                        │
│                  ▼                                        │
│  ┌─────────────────────────────────────────────┐        │
│  │ Job 2: Build Flutter APK                    │        │
│  │  - Setup Flutter                            │        │
│  │  - Download Rust artifacts                  │        │
│  │  - flutter pub get                          │        │
│  │  - Decode keystore from secret              │        │
│  │  - flutter build apk --release              │        │
│  │  - Sign APK                                 │        │
│  │  - Calculate SHA256 hash                    │        │
│  │  - Upload APK artifact                      │        │
│  └─────────────────────────────────────────────┘        │
│                  │                                        │
│                  ▼                                        │
│  ┌─────────────────────────────────────────────┐        │
│  │ Job 3: Create GitHub Release                │        │
│  │  - Download APK artifact                    │        │
│  │  - Create release with notes                │        │
│  │  - Upload APK to release                    │        │
│  │  - Update zapstore.yaml (optional)          │        │
│  └─────────────────────────────────────────────┘        │
└─────────────────┬───────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────┐
│  GitHub Releases                                         │
│  - app-release.apk                                       │
│  - SHA256 checksum                                       │
│  - Release notes                                         │
└─────────────────┬───────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────┐
│  手動操作: Nostr イベント発行                            │
│  - ZapStore で新規アプリ/更新を作成                     │
│  - zapstore.yaml の情報を入力                           │
│  - GitHub Release の APK URL を指定                     │
│  - NIP-89 イベント (kind: 32267) を発行                │
└─────────────────┬───────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────┐
│  ZapStore (Nostr リレー経由)                            │
│  - ユーザーがアプリを発見・インストール可能             │
└─────────────────────────────────────────────────────────┘
```

---

## 🛠️ セットアップ手順

### ステップ 1: GitHub Secrets の設定

リポジトリの **Settings > Secrets and variables > Actions** で以下のシークレットを追加：

| Secret 名 | 説明 | 例 |
|-----------|------|-----|
| `KEYSTORE_BASE64` | Base64 エンコードしたキーストア | `MIIKvQIBAz...` |
| `KEYSTORE_PASSWORD` | キーストアのパスワード | `your_keystore_password` |
| `KEY_ALIAS` | キーのエイリアス | `upload` |
| `KEY_PASSWORD` | キーのパスワード | `your_key_password` |
| `NOSTR_PRIVATE_KEY` | (オプション) Nostr 秘密鍵 | `nsec1...` |

### ステップ 2: ワークフローファイルの作成

`.github/workflows/release.yml` を作成します（後述）。

### ステップ 3: key.properties の設定

**⚠️ ローカル環境のみ**: `android/key.properties` を作成（`.gitignore` に追加済み）:

```properties
storePassword=your_keystore_password
keyPassword=your_key_password
keyAlias=upload
storeFile=upload-keystore.jks
```

このファイルは Git にコミットしません。GitHub Actions では環境変数から生成します。

### ステップ 4: build.gradle.kts の署名設定

`android/app/build.gradle.kts` に署名設定を追加：

```kotlin
android {
    // ...
    
    signingConfigs {
        create("release") {
            // CI 環境では環境変数から取得
            storeFile = System.getenv("KEYSTORE_FILE")?.let { file(it) }
                ?: file("../../upload-keystore.jks")
            storePassword = System.getenv("KEYSTORE_PASSWORD")
            keyAlias = System.getenv("KEY_ALIAS")
            keyPassword = System.getenv("KEY_PASSWORD")
        }
    }
    
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            // ...
        }
    }
}
```

---

## 🤖 GitHub Actions ワークフロー

`.github/workflows/release.yml` を作成：

```yaml
name: Release to ZapStore

on:
  push:
    tags:
      - 'v*.*.*'  # v1.0.0, v1.2.3 などのタグにマッチ
  workflow_dispatch:  # 手動実行も可能

env:
  FLUTTER_VERSION: '3.9.2'
  RUST_VERSION: '1.75'

jobs:
  build-rust:
    name: Build Rust Libraries
    runs-on: ubuntu-latest
    strategy:
      matrix:
        target:
          - aarch64-linux-android     # arm64-v8a
          - armv7-linux-androideabi   # armeabi-v7a
          - x86_64-linux-android      # x86_64
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Setup Rust
        uses: dtolnay/rust-toolchain@stable
        with:
          toolchain: ${{ env.RUST_VERSION }}
          targets: ${{ matrix.target }}
      
      - name: Install cargo-ndk
        run: cargo install cargo-ndk
      
      - name: Cache Rust dependencies
        uses: actions/cache@v4
        with:
          path: |
            ~/.cargo/bin/
            ~/.cargo/registry/index/
            ~/.cargo/registry/cache/
            ~/.cargo/git/db/
            rust/target/
          key: ${{ runner.os }}-cargo-${{ matrix.target }}-${{ hashFiles('**/Cargo.lock') }}
      
      - name: Build Rust library
        run: |
          cd rust
          
          # アーキテクチャに応じた NDK ターゲット名を設定
          case "${{ matrix.target }}" in
            aarch64-linux-android)
              NDK_TARGET="arm64-v8a"
              ;;
            armv7-linux-androideabi)
              NDK_TARGET="armeabi-v7a"
              ;;
            x86_64-linux-android)
              NDK_TARGET="x86_64"
              ;;
          esac
          
          echo "Building for $NDK_TARGET"
          cargo ndk -t $NDK_TARGET -o ../android/app/src/main/jniLibs build --release
      
      - name: Upload Rust artifacts
        uses: actions/upload-artifact@v4
        with:
          name: rust-${{ matrix.target }}
          path: android/app/src/main/jniLibs/
          retention-days: 1

  build-apk:
    name: Build Flutter APK
    runs-on: ubuntu-latest
    needs: build-rust
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Setup Java
        uses: actions/setup-java@v4
        with:
          distribution: 'zulu'
          java-version: '17'
      
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: ${{ env.FLUTTER_VERSION }}
          cache: true
      
      - name: Download Rust artifacts (arm64-v8a)
        uses: actions/download-artifact@v4
        with:
          name: rust-aarch64-linux-android
          path: android/app/src/main/jniLibs/
      
      - name: Download Rust artifacts (armeabi-v7a)
        uses: actions/download-artifact@v4
        with:
          name: rust-armv7-linux-androideabi
          path: android/app/src/main/jniLibs/
      
      - name: Download Rust artifacts (x86_64)
        uses: actions/download-artifact@v4
        with:
          name: rust-x86_64-linux-android
          path: android/app/src/main/jniLibs/
      
      - name: Verify jniLibs
        run: |
          echo "Checking jniLibs directory structure:"
          find android/app/src/main/jniLibs -type f
      
      - name: Get dependencies
        run: flutter pub get
      
      - name: Generate localization
        run: flutter gen-l10n
      
      - name: Decode keystore
        run: |
          echo "${{ secrets.KEYSTORE_BASE64 }}" | base64 -d > android/app/upload-keystore.jks
      
      - name: Create key.properties
        run: |
          cat > android/key.properties << EOF
          storePassword=${{ secrets.KEYSTORE_PASSWORD }}
          keyPassword=${{ secrets.KEY_PASSWORD }}
          keyAlias=${{ secrets.KEY_ALIAS }}
          storeFile=upload-keystore.jks
          EOF
      
      - name: Build APK
        env:
          KEYSTORE_FILE: android/app/upload-keystore.jks
          KEYSTORE_PASSWORD: ${{ secrets.KEYSTORE_PASSWORD }}
          KEY_ALIAS: ${{ secrets.KEY_ALIAS }}
          KEY_PASSWORD: ${{ secrets.KEY_PASSWORD }}
        run: |
          flutter build apk --release
      
      - name: Calculate APK hash
        id: apk_hash
        run: |
          APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
          HASH=$(sha256sum "$APK_PATH" | awk '{print $1}')
          echo "hash=$HASH" >> $GITHUB_OUTPUT
          echo "APK SHA256: $HASH"
      
      - name: Get APK size
        run: |
          APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
          SIZE=$(du -h "$APK_PATH" | cut -f1)
          echo "APK Size: $SIZE"
      
      - name: Upload APK artifact
        uses: actions/upload-artifact@v4
        with:
          name: app-release
          path: build/app/outputs/flutter-apk/app-release.apk
      
      - name: Upload APK hash
        uses: actions/upload-artifact@v4
        with:
          name: apk-hash
          path: |
            echo "${{ steps.apk_hash.outputs.hash }}" > apk-hash.txt

  create-release:
    name: Create GitHub Release
    runs-on: ubuntu-latest
    needs: build-apk
    permissions:
      contents: write
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Download APK
        uses: actions/download-artifact@v4
        with:
          name: app-release
          path: ./
      
      - name: Get version from tag
        id: get_version
        run: |
          VERSION=${GITHUB_REF#refs/tags/v}
          echo "version=$VERSION" >> $GITHUB_OUTPUT
      
      - name: Calculate APK hash
        id: apk_hash
        run: |
          HASH=$(sha256sum app-release.apk | awk '{print $1}')
          echo "hash=$HASH" >> $GITHUB_OUTPUT
      
      - name: Create release notes
        run: |
          cat > release-notes.md << 'EOF'
          ## ZapClock v${{ steps.get_version.outputs.version }}
          
          ### 📱 インストール方法
          
          #### ZapStore 経由 (推奨)
          1. [ZapStore](https://zapstore.dev/) アプリをインストール
          2. "ZapClock" を検索
          3. インストールボタンをタップ
          
          #### 直接インストール
          以下の APK をダウンロードしてインストール:
          - `app-release.apk` (SHA256: `${{ steps.apk_hash.outputs.hash }}`)
          
          ### 📝 変更履歴
          
          このバージョンの変更内容は [CHANGELOG.md](https://github.com/${{ github.repository }}/blob/main/CHANGELOG.md) を参照してください。
          
          ### 🔒 セキュリティ
          
          **APK ハッシュ値 (SHA256)**:
          ```
          ${{ steps.apk_hash.outputs.hash }}
          ```
          
          インストール前に以下のコマンドで検証できます:
          ```bash
          sha256sum app-release.apk
          ```
          
          ### 📚 ドキュメント
          
          - [README](https://github.com/${{ github.repository }}/blob/main/README.md)
          - [ZapStore リリースガイド](https://github.com/${{ github.repository }}/blob/main/ZAPSTORE_RELEASE.md)
          
          ### ⚡ ZapStore 情報
          
          このアプリは Nostr ベースの ZapStore で配布されています。
          - Nostr イベント kind: 32267
          - アプリ ID: `com.zapclock.zap_clock`
          
          ---
          
          Built with ⚡ and ❤️ by the ZapClock Team
          EOF
      
      - name: Create Release
        uses: softprops/action-gh-release@v1
        with:
          files: app-release.apk
          body_path: release-notes.md
          draft: false
          prerelease: false
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      
      - name: Output release info
        run: |
          echo "✅ Release created successfully!"
          echo "📦 APK URL: https://github.com/${{ github.repository }}/releases/download/${{ github.ref_name }}/app-release.apk"
          echo "🔐 SHA256: ${{ steps.apk_hash.outputs.hash }}"
          echo ""
          echo "🚀 Next steps:"
          echo "1. Access ZapStore website: https://zapstore.dev/"
          echo "2. Create or update app entry"
          echo "3. Use the APK URL above"
          echo "4. Publish Nostr event (kind: 32267)"
```

---

## 🚀 リリース手順

### ステップ 1: バージョン番号の更新

```bash
# pubspec.yaml
version: 1.0.1+2  # 1.0.1 がバージョン名, 2 がバージョンコード

# zapstore.yaml
version: "1.0.1"
versionCode: 2
```

### ステップ 2: CHANGELOG の更新

```bash
# CHANGELOG.md に変更内容を追記
echo "## v1.0.1 (2025-10-28)
- 🐛 Bug fixes
- ✨ New features
" >> CHANGELOG.md
```

### ステップ 3: コミット & タグ作成

```bash
git add pubspec.yaml zapstore.yaml CHANGELOG.md
git commit -m "chore: bump version to v1.0.1"
git push origin main

# タグを作成 (これが GitHub Actions をトリガーします)
git tag v1.0.1
git push origin v1.0.1
```

### ステップ 4: GitHub Actions の実行確認

1. GitHub リポジトリの **Actions** タブを開く
2. "Release to ZapStore" ワークフローが実行中であることを確認
3. 各ジョブのログを確認:
   - ✅ Build Rust Libraries (3つのターゲット)
   - ✅ Build Flutter APK
   - ✅ Create GitHub Release

### ステップ 5: リリースの確認

1. **Releases** タブを開く
2. 新しいリリース `v1.0.1` が作成されていることを確認
3. `app-release.apk` がアップロードされていることを確認
4. SHA256 ハッシュ値をメモ

### ステップ 6: ZapStore への登録

#### 6.1 ZapStore にアクセス

```bash
# ブラウザで開く
open https://zapstore.dev/
```

Nostr 拡張機能 (Alby など) でログイン。

#### 6.2 アプリの作成/更新

**新規リリースの場合**:
1. "Create App" をクリック
2. アプリ情報を入力 (`zapstore.yaml` の内容を参考に)
3. APK URL を指定:
   ```
   https://github.com/YOUR_USERNAME/zap_clock/releases/download/v1.0.1/app-release.apk
   ```
4. SHA256 ハッシュを入力

**更新の場合**:
1. 既存のアプリを選択
2. "Update" をクリック
3. 新しいバージョン情報を入力
4. 新しい APK URL とハッシュを指定

#### 6.3 Nostr イベントの発行

ZapStore の UI で "Publish" をクリックすると、以下の Nostr イベントが発行されます:

```json
{
  "kind": 32267,
  "tags": [
    ["d", "com.zapclock.zap_clock"],
    ["name", "ZapClock"],
    ["version", "1.0.1"],
    ["url", "https://github.com/.../app-release.apk"],
    ["sha256", "abcdef..."],
    ["description", "Lightning送金で停止するアラームアプリ"],
    ["icon", "https://..."],
    ...
  ],
  "content": "...",
  ...
}
```

### ステップ 7: 動作確認

1. ZapStore アプリ (Android) で "ZapClock" を検索
2. 新しいバージョンが表示されることを確認
3. インストールして動作確認

---

## 🐛 トラブルシューティング

### ビルドエラー: Rust ライブラリが見つからない

**原因**: jniLibs ディレクトリが正しく配置されていない

**解決方法**:
```bash
# ローカルで確認
find android/app/src/main/jniLibs -type f

# 期待される構造:
# jniLibs/
#   arm64-v8a/
#     libnative.so
#   armeabi-v7a/
#     libnative.so
#   x86_64/
#     libnative.so
```

ワークフローの "Verify jniLibs" ステップのログを確認。

### 署名エラー: keystore が無効

**原因**: GitHub Secrets の `KEYSTORE_BASE64` が正しくない

**解決方法**:
```bash
# キーストアを再エンコード
base64 -i upload-keystore.jks | pbcopy

# GitHub Secrets を更新
# Settings > Secrets > KEYSTORE_BASE64
```

### APK サイズが大きすぎる

**原因**: すべてのアーキテクチャが含まれている

**解決方法**:

Option 1: Split APK を使用
```yaml
# ワークフローを修正
- name: Build APK
  run: flutter build apk --release --split-per-abi
```

Option 2: App Bundle を使用 (将来的に ZapStore が対応した場合)
```yaml
- name: Build App Bundle
  run: flutter build appbundle --release
```

### GitHub Actions の実行時間が長い

**原因**: Rust のビルドに時間がかかる

**最適化**:
1. キャッシュを有効化 (ワークフローに含まれています)
2. `cargo-ndk` のバージョンを固定
3. 並列ビルドを活用 (matrix strategy で実装済み)

### ZapStore でアプリが見つからない

**原因**:
- Nostr イベントがリレーに伝播していない
- `identifier` が重複している
- メタデータが不完全

**解決方法**:
1. 複数の Nostr リレーを使用
2. `zapstore.yaml` の `identifier` をユニークにする
3. ZapStore のサポートに連絡

### タグのプッシュで Actions がトリガーされない

**原因**: タグの形式が正しくない

**解決方法**:
```bash
# 正しい形式: v1.0.0, v2.1.3 など
git tag v1.0.0  # ✅ OK
git tag 1.0.0   # ❌ NG (vプレフィックスが必要)
git tag release-1.0.0  # ❌ NG (パターンにマッチしない)

# タグを削除して再作成
git tag -d v1.0.0
git push origin :refs/tags/v1.0.0
git tag v1.0.0
git push origin v1.0.0
```

---

## 📚 参考情報

### GitHub Actions 関連

- [GitHub Actions ドキュメント](https://docs.github.com/ja/actions)
- [Flutter Action](https://github.com/marketplace/actions/flutter-action)
- [Rust Toolchain Action](https://github.com/marketplace/actions/rust-toolchain)

### ZapStore 関連

- [ZapStore 公式サイト](https://zapstore.dev/)
- [NIP-89 仕様](https://github.com/nostr-protocol/nips/blob/master/89.md)
- [ZapStore GitHub](https://github.com/zapstore)

### Nostr 関連

- [Nostr 公式サイト](https://nostr.com/)
- [NIPs (Nostr Implementation Possibilities)](https://github.com/nostr-protocol/nips)
- [Awesome Nostr](https://github.com/aljazceru/awesome-nostr)

---

## 💡 ベストプラクティス

### 1. セマンティックバージョニング

```
v<major>.<minor>.<patch>

例:
- v1.0.0: 初回リリース
- v1.0.1: バグ修正
- v1.1.0: 新機能追加 (後方互換性あり)
- v2.0.0: 破壊的変更
```

### 2. CHANGELOG の管理

```markdown
# CHANGELOG.md

## [Unreleased]

## [1.0.1] - 2025-10-28
### Fixed
- アラーム音が鳴らない問題を修正

### Added
- ダークテーマのサポート

## [1.0.0] - 2025-10-25
### Added
- 初回リリース
```

### 3. リリースノートの自動生成

GitHub の Release Notes 自動生成機能を使用:

```yaml
- name: Create Release
  uses: softprops/action-gh-release@v1
  with:
    generate_release_notes: true  # 追加
```

### 4. タグの保護

重要なタグを誤って削除しないよう保護:

1. **Settings > Tags** を開く
2. "Add rule" をクリック
3. Tag name pattern: `v*`
4. ルールを設定

### 5. リリースブランチの使用

安定版のリリースには専用ブランチを使用:

```bash
# リリースブランチを作成
git checkout -b release/v1.0.0

# 最終調整
# ...

# マージしてタグを作成
git checkout main
git merge release/v1.0.0
git tag v1.0.0
git push origin main v1.0.0
```

---

## 🔐 セキュリティ考慮事項

### 1. シークレットの管理

- ✅ GitHub Secrets を使用
- ❌ コードにハードコードしない
- ❌ ログに出力しない

### 2. APK の署名

- 本番用と開発用で別のキーストアを使用
- キーストアのバックアップを安全に保管
- パスワードを定期的に変更

### 3. 依存関係のセキュリティ

```yaml
# Dependabot を有効化
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: "pub"
    directory: "/"
    schedule:
      interval: "weekly"
  
  - package-ecosystem: "cargo"
    directory: "/rust"
    schedule:
      interval: "weekly"
```

---

## ✅ チェックリスト

リリース前に以下を確認:

### コード

- [ ] すべてのテストがパス
- [ ] Lint エラーがない
- [ ] バージョン番号を更新 (`pubspec.yaml`, `zapstore.yaml`)
- [ ] CHANGELOG を更新

### GitHub

- [ ] GitHub Secrets が設定済み
- [ ] ワークフローファイルが最新
- [ ] `.gitignore` に機密情報のファイルを追加

### ZapStore

- [ ] `zapstore.yaml` が完全
- [ ] スクリーンショットを準備
- [ ] Nostr アカウントを設定

### リリース後

- [ ] GitHub Release が作成された
- [ ] APK がアップロードされた
- [ ] SHA256 ハッシュを確認
- [ ] ZapStore にアプリを登録
- [ ] Nostr イベントを発行
- [ ] ZapStore アプリで検索可能か確認
- [ ] 実機でインストール・動作確認

---

## 🎉 完了!

これで GitHub Actions を使った自動リリースプロセスが完成です！

**次回からは**:
1. コードを更新
2. バージョン番号を更新
3. `git tag v1.x.x && git push origin v1.x.x`
4. GitHub Actions が自動実行
5. ZapStore で公開

**⚡ Happy Zapping! ⚡**

---

_作成日: 2025-10-28_
_最終更新: 2025-10-28_

