# ZapStore リリース クイックスタート ⚡️

このガイドでは、GitHub Actions を使った ZapStore への自動リリースを最速でセットアップする方法を説明します。

---

## 🎯 ゴール

タグをプッシュするだけで、自動的に APK がビルドされて GitHub Releases にアップロードされる環境を構築します。

---

## ⏱️ 所要時間

- 初回セットアップ: **約 15 分**
- 2 回目以降のリリース: **約 2 分** (ほぼ自動)

---

## 📝 前提条件

- ✅ Git がインストール済み
- ✅ Java 11+ がインストール済み (Android 開発用)
- ✅ GitHub アカウントがある
- ✅ ZapClock プロジェクトをフォーク済み

---

## 🚀 セットアップ (初回のみ)

### ステップ 1: Android キーストアの作成 (5 分)

```bash
cd /Users/apple/work/zap_clock

# キーストアを生成
keytool -genkey -v \
  -keystore upload-keystore.jks \
  -alias upload \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000

# パスワードを入力 (2回)
# あなたの情報を入力 (名前、組織など)
```

**⚠️ パスワードをメモしてください！**

### ステップ 2: GitHub Secrets の設定 (5 分)

```bash
# キーストアを Base64 エンコード
base64 -i upload-keystore.jks | pbcopy
```

GitHub リポジトリで:
1. **Settings** > **Secrets and variables** > **Actions**
2. **New repository secret** をクリック
3. 以下の 4 つのシークレットを追加:

| Name | Value |
|------|-------|
| `KEYSTORE_BASE64` | (クリップボードの内容) |
| `KEYSTORE_PASSWORD` | (入力したパスワード) |
| `KEY_ALIAS` | `upload` |
| `KEY_PASSWORD` | (入力したキーのパスワード) |

### ステップ 3: ワークフローの確認 (2 分)

以下のファイルが存在することを確認:

```bash
ls -la .github/workflows/release.yml
ls -la android/app/proguard-rules.pro
```

**すでに存在します！** 何もする必要はありません。

### ステップ 4: テストリリース (3 分)

```bash
# 変更をコミット
git add .
git commit -m "ci: setup GitHub Actions release workflow"
git push origin main

# テストタグを作成
git tag v0.0.1-test
git push origin v0.0.1-test
```

GitHub の **Actions** タブを開いて進行状況を確認してください。

---

## 🎉 本番リリース (2 回目以降)

### リリースの流れ

```bash
# 1. バージョンを更新
vim pubspec.yaml      # version: 1.0.1+2
vim zapstore.yaml     # version: "1.0.1", versionCode: 2

# 2. CHANGELOG を更新
vim CHANGELOG.md

# 3. コミット
git add pubspec.yaml zapstore.yaml CHANGELOG.md
git commit -m "chore: bump version to v1.0.1"
git push origin main

# 4. タグを作成 (これが GitHub Actions をトリガー)
git tag v1.0.1
git push origin v1.0.1
```

### 自動実行される内容

1. ✅ Rust ライブラリのビルド (arm64-v8a, armeabi-v7a, x86_64)
2. ✅ Flutter APK のビルド
3. ✅ APK への署名
4. ✅ GitHub Release の作成
5. ✅ APK のアップロード

**所要時間: 約 10-15 分**

### ZapStore への公開

GitHub Actions が完了したら:

1. [ZapStore](https://zapstore.dev/) にアクセス
2. Nostr 拡張機能でログイン
3. アプリを作成/更新
4. APK URL を入力:
   ```
   https://github.com/YOUR_USERNAME/zap_clock/releases/download/v1.0.1/app-release.apk
   ```
5. SHA256 ハッシュを入力 (GitHub Release に記載)
6. "Publish" をクリック

**完了！** 🎉

---

## 📊 リリースの確認

### GitHub で確認

```bash
# ブラウザで開く
open "https://github.com/YOUR_USERNAME/zap_clock/releases"
```

### ZapStore で確認

1. ZapStore アプリ (Android) をインストール
2. "ZapClock" を検索
3. 新しいバージョンが表示されることを確認

---

## 🐛 問題が発生した場合

### ビルドが失敗する

**Actions タブでログを確認:**
```
GitHub > Your Repo > Actions > 失敗したワークフロー > ログを確認
```

**よくあるエラー:**

| エラー | 原因 | 解決方法 |
|--------|------|----------|
| "Keystore file not found" | Secrets が未設定 | [ステップ 2](#ステップ-2-github-secrets-の設定-5-分) を確認 |
| "Wrong password" | パスワードが間違っている | Secrets を再設定 |
| "Rust library not found" | jniLibs が見つからない | ワークフローログを確認 |

### 詳細なトラブルシューティング

詳しくは以下を参照:
- [GITHUB_ACTIONS_RELEASE.md - トラブルシューティング](GITHUB_ACTIONS_RELEASE.md#-トラブルシューティング)
- [GITHUB_ACTIONS_SETUP.md - トラブルシューティング](GITHUB_ACTIONS_SETUP.md#-トラブルシューティング)

---

## 📚 詳細ドキュメント

さらに詳しい情報が必要な場合:

1. **[GITHUB_ACTIONS_SETUP.md](GITHUB_ACTIONS_SETUP.md)** - 詳細なセットアップ手順
2. **[GITHUB_ACTIONS_RELEASE.md](GITHUB_ACTIONS_RELEASE.md)** - リリースプロセスの詳細
3. **[ZAPSTORE_RELEASE.md](ZAPSTORE_RELEASE.md)** - 手動リリースの手順
4. **[ZAPSTORE_CHECKLIST.md](ZAPSTORE_CHECKLIST.md)** - リリース前チェックリスト

---

## ✅ チェックリスト

### 初回セットアップ

- [ ] Android キーストアを生成
- [ ] GitHub Secrets を設定 (4 つ)
- [ ] テストタグでビルド成功を確認
- [ ] GitHub Release が作成されることを確認

### リリース前

- [ ] `pubspec.yaml` のバージョン更新
- [ ] `zapstore.yaml` のバージョン更新
- [ ] `CHANGELOG.md` を更新
- [ ] コミット & プッシュ
- [ ] タグを作成 & プッシュ

### リリース後

- [ ] GitHub Actions が成功したか確認
- [ ] GitHub Release が作成されたか確認
- [ ] APK がダウンロード可能か確認
- [ ] ZapStore でアプリを更新
- [ ] ZapStore で検索可能か確認
- [ ] 実機でインストール & 動作確認

---

## 🎯 次のステップ

1. **スクリーンショットの撮影**
   ```bash
   # screenshots/ ディレクトリに保存
   # 01_alarm_list.png
   # 02_alarm_edit.png
   # 03_alarm_ring.png
   # 04_settings.png
   ```

2. **Nostr アカウントの準備**
   - [Alby](https://getalby.com/) をインストール
   - Nostr 鍵を取得
   - `zapstore.yaml` に公開鍵を追加

3. **ZapStore での公開**
   - アプリ情報を入力
   - スクリーンショットをアップロード
   - Nostr イベント (kind: 32267) を発行

---

## 💡 ヒント

### タグの命名規則

```bash
# ✅ 正しい
v1.0.0
v1.2.3
v2.0.0-beta

# ❌ 間違い
1.0.0      # v プレフィックスが必要
release-1.0.0
```

### バージョン管理

```yaml
# pubspec.yaml
version: 1.0.1+2  # 1.0.1 = バージョン名, 2 = ビルド番号

# zapstore.yaml
version: "1.0.1"
versionCode: 2
```

### 便利なエイリアス

```bash
# ~/.zshrc または ~/.bashrc に追加
alias release='f() { git tag v$1 && git push origin v$1; }; f'

# 使い方
release 1.0.1  # v1.0.1 タグを作成してプッシュ
```

---

## 🎉 おめでとうございます！

これで GitHub Actions を使った自動リリース環境が整いました！

**次回からは**:
1. バージョン更新
2. タグをプッシュ
3. コーヒーを飲みながら待つ ☕
4. ZapStore で公開

**⚡ Happy Zapping! ⚡**

---

_作成日: 2025-10-28_
_最終更新: 2025-10-28_

