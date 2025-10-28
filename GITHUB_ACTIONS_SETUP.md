# GitHub Actions セットアップガイド 🔧

このドキュメントでは、GitHub Actions を使った自動リリースの初期セットアップ手順を説明します。

---

## 📋 目次

1. [Android 署名鍵の作成](#android-署名鍵の作成)
2. [GitHub Secrets の設定](#github-secrets-の設定)
3. [build.gradle.kts の設定](#buildgradlekts-の設定)
4. [.gitignore の確認](#gitignore-の確認)
5. [初回リリーステスト](#初回リリーステスト)

---

## 🔐 Android 署名鍵の作成

### ステップ 1: キーストアファイルの生成

```bash
# プロジェクトルートで実行
cd /Users/apple/work/zap_clock

# キーストアを生成
keytool -genkey -v \
  -keystore upload-keystore.jks \
  -alias upload \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000
```

### 入力項目

以下の情報を入力します:

```
キーストアのパスワードを入力してください: [パスワードを入力]
新規パスワードを再入力してください: [同じパスワードを再入力]

姓名は何ですか。
  [CN]: ZapClock Team
組織単位名は何ですか。
  [OU]: Development
組織名は何ですか。
  [O]: ZapClock
市区町村名は何ですか。
  [L]: Tokyo
都道府県名または州名は何ですか。
  [ST]: Tokyo
この単位に該当する2文字の国コードは何ですか。
  [C]: JP

CN=ZapClock Team, OU=Development, O=ZapClock, L=Tokyo, ST=Tokyo, C=JP でよろしいですか。
  [no]: yes

<upload>のキー・パスワードを入力してください
        (キーストアのパスワードと同じ場合はRETURNを押してください): [キーのパスワード]
```

### ステップ 2: キーストア情報の記録

**⚠️ 重要**: 以下の情報を安全な場所に保存してください：

```
Keystore file: upload-keystore.jks
Keystore password: [入力したパスワード]
Key alias: upload
Key password: [入力したキーのパスワード]
```

### ステップ 3: キーストアのバックアップ

```bash
# 安全な場所にバックアップ (例: 1Password, LastPass など)
cp upload-keystore.jks ~/Backups/zap_clock_keystore_$(date +%Y%m%d).jks

# または暗号化してクラウドに保存
# gpg -c upload-keystore.jks
# mv upload-keystore.jks.gpg ~/Dropbox/Backups/
```

**⚠️ 注意**: このキーストアを紛失すると、アプリの更新ができなくなります！

---

## 🔑 GitHub Secrets の設定

### ステップ 1: キーストアのエンコード

```bash
# macOS
base64 -i upload-keystore.jks | pbcopy
echo "✅ キーストアの Base64 文字列をクリップボードにコピーしました"

# Linux
base64 -w 0 upload-keystore.jks | xclip -selection clipboard
# または
base64 -w 0 upload-keystore.jks > keystore.b64
cat keystore.b64

# Windows (PowerShell)
[Convert]::ToBase64String([IO.File]::ReadAllBytes("upload-keystore.jks")) | Set-Clipboard
```

### ステップ 2: GitHub リポジトリで Secrets を設定

1. GitHub リポジトリを開く
2. **Settings** タブをクリック
3. 左サイドバーの **Secrets and variables > Actions** をクリック
4. **New repository secret** をクリック

#### シークレット 1: KEYSTORE_BASE64

```
Name: KEYSTORE_BASE64
Secret: [貼り付けた Base64 文字列]
```

**Add secret** をクリック

#### シークレット 2: KEYSTORE_PASSWORD

```
Name: KEYSTORE_PASSWORD
Secret: [キーストアのパスワード]
```

#### シークレット 3: KEY_ALIAS

```
Name: KEY_ALIAS
Secret: upload
```

#### シークレット 4: KEY_PASSWORD

```
Name: KEY_PASSWORD
Secret: [キーのパスワード]
```

### ステップ 3: Secrets の確認

以下の 4 つのシークレットが設定されていることを確認:

- ✅ `KEYSTORE_BASE64`
- ✅ `KEYSTORE_PASSWORD`
- ✅ `KEY_ALIAS`
- ✅ `KEY_PASSWORD`

---

## ⚙️ build.gradle.kts の設定

### ステップ 1: ファイルを開く

```bash
code android/app/build.gradle.kts
```

### ステップ 2: 署名設定を追加

`android { }` ブロック内に以下を追加:

```kotlin
android {
    // ... 既存の設定 ...
    
    signingConfigs {
        create("release") {
            // CI 環境では環境変数から取得
            val keystoreFile = System.getenv("KEYSTORE_FILE")?.let { file(it) }
                ?: rootProject.file("upload-keystore.jks")
            
            if (keystoreFile.exists()) {
                storeFile = keystoreFile
                storePassword = System.getenv("KEYSTORE_PASSWORD")
                keyAlias = System.getenv("KEY_ALIAS")
                keyPassword = System.getenv("KEY_PASSWORD")
            } else {
                // ローカル開発環境では key.properties から取得
                val keystorePropertiesFile = rootProject.file("key.properties")
                if (keystorePropertiesFile.exists()) {
                    val keystoreProperties = java.util.Properties()
                    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
                    
                    storeFile = file(keystoreProperties["storeFile"] as String)
                    storePassword = keystoreProperties["storePassword"] as String
                    keyAlias = keystoreProperties["keyAlias"] as String
                    keyPassword = keystoreProperties["keyPassword"] as String
                }
            }
        }
    }
    
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}
```

### ステップ 3: ローカル開発用の key.properties 作成

```bash
# android/key.properties を作成
cat > android/key.properties << EOF
storePassword=[あなたのキーストアパスワード]
keyPassword=[あなたのキーパスワード]
keyAlias=upload
storeFile=../upload-keystore.jks
EOF
```

**⚠️ 重要**: このファイルは Git にコミットしないこと！

---

## 📝 .gitignore の確認

### ステップ 1: .gitignore に追加

```bash
# プロジェクトルートで実行
cat >> .gitignore << EOF

# Android 署名鍵 (絶対に Git にコミットしないこと!)
*.jks
*.keystore
android/key.properties
upload-keystore.jks
keystore.b64

# CI 環境で生成される一時ファイル
android/app/upload-keystore.jks
EOF
```

### ステップ 2: 既存のキーストアが Git に含まれていないか確認

```bash
# キーストアファイルが追跡されていないことを確認
git status

# もし追跡されている場合は削除
git rm --cached upload-keystore.jks
git rm --cached android/key.properties
git commit -m "chore: remove keystore files from git"
```

---

## 🧪 初回リリーステスト

### ステップ 1: テスト用タグの作成

```bash
# 変更をコミット
git add .github/workflows/release.yml
git commit -m "ci: add GitHub Actions release workflow"
git push origin main

# テスト用タグを作成
git tag v0.0.1-test
git push origin v0.0.1-test
```

### ステップ 2: Actions の実行確認

1. GitHub リポジトリの **Actions** タブを開く
2. "Release to ZapStore" ワークフローをクリック
3. 実行中のジョブを確認:
   - Build Rust Libraries (arm64-v8a)
   - Build Rust Libraries (armeabi-v7a)
   - Build Rust Libraries (x86_64)
   - Build Flutter APK
   - Create GitHub Release

### ステップ 3: ログの確認

各ジョブのログを確認して、エラーがないかチェック:

#### Build Rust Libraries

```
✅ Setup Rust
✅ Install cargo-ndk
✅ Setup Android NDK
✅ Build Rust library
✅ Upload Rust artifacts
```

#### Build Flutter APK

```
✅ Setup Java
✅ Setup Flutter
✅ Download Rust artifacts
✅ Verify jniLibs
✅ Get dependencies
✅ Generate localization
✅ Decode keystore
✅ Create key.properties
✅ Build APK
✅ Calculate APK hash
✅ Upload APK artifact
```

#### Create GitHub Release

```
✅ Download APK
✅ Get version from tag
✅ Calculate APK hash
✅ Create release notes
✅ Create Release
✅ Output release info
```

### ステップ 4: リリースの確認

1. **Releases** タブを開く
2. `v0.0.1-test` リリースが作成されていることを確認
3. `app-release.apk` がアップロードされていることを確認
4. リリースノートが生成されていることを確認

### ステップ 5: APK のダウンロードとインストール

```bash
# APK をダウンロード
curl -L -o app-release.apk \
  https://github.com/YOUR_USERNAME/zap_clock/releases/download/v0.0.1-test/app-release.apk

# SHA256 ハッシュを確認
sha256sum app-release.apk

# Android デバイスにインストール
adb install app-release.apk
```

### ステップ 6: テストタグの削除 (オプション)

```bash
# ローカルのタグを削除
git tag -d v0.0.1-test

# リモートのタグを削除
git push origin :refs/tags/v0.0.1-test

# GitHub でリリースを削除
# (GitHub UI から手動で削除)
```

---

## ❌ トラブルシューティング

### エラー: "Keystore file not found"

**原因**: GitHub Secrets が正しく設定されていない

**解決方法**:
1. GitHub Secrets を確認
2. `KEYSTORE_BASE64` が正しくエンコードされているか確認
3. Base64 文字列に改行や空白が含まれていないか確認

### エラー: "Wrong password"

**原因**: パスワードが間違っている

**解決方法**:
1. `KEYSTORE_PASSWORD` と `KEY_PASSWORD` を確認
2. ローカルで動作確認:
   ```bash
   keytool -list -v -keystore upload-keystore.jks -alias upload
   ```

### エラー: "Rust library not found"

**原因**: jniLibs のパスが間違っている

**解決方法**:
1. ワークフローの "Verify jniLibs" ステップのログを確認
2. 期待されるディレクトリ構造:
   ```
   android/app/src/main/jniLibs/
   ├── arm64-v8a/
   │   └── libnative.so
   ├── armeabi-v7a/
   │   └── libnative.so
   └── x86_64/
       └── libnative.so
   ```

### エラー: "Flutter command not found"

**原因**: Flutter のセットアップに失敗

**解決方法**:
1. `FLUTTER_VERSION` を確認
2. `subosito/flutter-action@v2` のバージョンを確認

### ワークフローが実行されない

**原因**: タグの形式が正しくない

**解決方法**:
```bash
# 正しい形式
git tag v1.0.0  # ✅ OK
git tag 1.0.0   # ❌ NG (v プレフィックスが必要)

# ワークフローのトリガー設定を確認
# on:
#   push:
#     tags:
#       - 'v*.*.*'
```

---

## ✅ セットアップ完了チェックリスト

### 準備

- [ ] Android キーストアを生成
- [ ] キーストア情報を安全に保存
- [ ] キーストアをバックアップ

### GitHub

- [ ] `KEYSTORE_BASE64` を設定
- [ ] `KEYSTORE_PASSWORD` を設定
- [ ] `KEY_ALIAS` を設定
- [ ] `KEY_PASSWORD` を設定

### プロジェクト

- [ ] `build.gradle.kts` に署名設定を追加
- [ ] `android/key.properties` を作成 (ローカル開発用)
- [ ] `.gitignore` にキーストアファイルを追加
- [ ] `.github/workflows/release.yml` を作成

### テスト

- [ ] テスト用タグをプッシュ
- [ ] GitHub Actions が実行された
- [ ] すべてのジョブが成功
- [ ] リリースが作成された
- [ ] APK がダウンロード可能
- [ ] APK がインストール可能

### クリーンアップ

- [ ] テストタグを削除 (オプション)
- [ ] テストリリースを削除 (オプション)

---

## 🎉 次のステップ

セットアップが完了したら、[GITHUB_ACTIONS_RELEASE.md](GITHUB_ACTIONS_RELEASE.md) を参照して実際のリリースを行ってください。

```bash
# 本番リリース
git tag v1.0.0
git push origin v1.0.0
```

**⚡ Happy Releasing! ⚡**

---

_作成日: 2025-10-28_
_最終更新: 2025-10-28_

