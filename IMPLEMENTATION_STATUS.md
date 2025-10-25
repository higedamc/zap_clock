# ZapClock 実装ステータス

## ✅ 完了した作業

### フェーズ1: ベーシックなアラームアプリ ✅

1. **プロジェクト構造の構築**
   - ✅ Flutter + Riverpod + GoRouter のセットアップ
   - ✅ Models/Providers/Services の実装
   - ✅ 3つのメイン画面の実装
     - アラーム一覧画面 (`alarm_list_screen.dart`)
     - アラーム編集画面 (`alarm_edit_screen.dart`)
     - アラーム鳴動画面 (`alarm_ring_screen.dart`)

2. **アラーム機能の実装**
   - ✅ `alarm` パッケージ (v5.1.5) への切り替え完了
   - ✅ アラームのスケジュール機能
   - ✅ アラームの鳴動機能
   - ✅ 繰り返しアラーム機能
   - ✅ アラーム音声の再生
   - ✅ バイブレーション
   - ✅ フェードイン機能（3秒）

3. **データ永続化**
   - ✅ SharedPreferences によるローカル保存
   - ✅ アラームデータの CRUD 操作

4. **UI/UX**
   - ✅ マテリアルデザイン3対応
   - ✅ ビットコイン/ライトニングをイメージしたカラーテーマ
   - ✅ アニメーション付きアラーム鳴動画面
   - ✅ レスポンシブデザイン

## 📋 次のステップ：動作確認

### 1. アラーム音声ファイルの準備（重要！）

現在、`assets/alarm_sound.mp3` にはシステムのAIFFファイルがコピーされています。
より良いアラーム音を使用したい場合は、以下の手順で置き換えてください：

```bash
# MP3ファイルを assets/alarm_sound.mp3 として配置
cp your_alarm_sound.mp3 /Users/apple/work/zap_clock/assets/alarm_sound.mp3
```

**推奨される音声ファイルの仕様：**
- フォーマット: MP3
- 長さ: 10〜30秒程度
- 音量: 適度な音量（アプリ側で0.8倍で再生）

**フリー素材サイト：**
- [効果音ラボ](https://soundeffect-lab.info/)
- [DOVA-SYNDROME](https://dova-s.jp/)
- [魔王魂](https://maou.audio/)

### 2. ビルドとテスト

```bash
cd /Users/apple/work/zap_clock

# ビルド
fvm flutter build apk --debug

# または実機/エミュレータで直接実行
fvm flutter run
```

### 3. テスト項目

#### 基本機能
- [ ] アラームを新規作成できる
- [ ] アラーム時刻を設定できる
- [ ] ラベルを設定できる
- [ ] 繰り返し曜日を設定できる
- [ ] アラームのON/OFF切り替えができる
- [ ] アラームを編集できる
- [ ] アラームを削除できる

#### アラーム鳴動
- [ ] 設定した時刻にアラームが鳴る
- [ ] 音声が再生される
- [ ] バイブレーションが動作する
- [ ] フェードイン（3秒）が機能する
- [ ] 画面ロック解除してアラーム画面が表示される
- [ ] 戻るボタンが無効化されている
- [ ] 停止ボタンでアラームが止まる

#### 繰り返しアラーム
- [ ] 繰り返し設定したアラームが次の曜日に再スケジュールされる
- [ ] 「毎日」「平日」「週末」が正しく表示される

#### データ永続性
- [ ] アプリを再起動してもアラームが保持される
- [ ] デバイス再起動後もアラームが動作する

## 🚀 フェーズ2: Lightning送金機能（未実装）

次のフェーズで実装予定：

### 実装予定の機能

1. **NWC (Nostr Wallet Connect) 統合**
   - Rust + flutter_rust_bridge
   - rust-nostr ライブラリの使用
   - NWC接続設定画面

2. **Lightning送金機能**
   - LightningアドレスからLNURL-payへの変換
   - invoiceの取得
   - NWC経由での支払い処理
   - 送金成功後にアラーム停止

3. **設定画面の追加**
   - NWC接続文字列の入力
   - Lightningアドレスの設定
   - 送金額（sats）の設定

4. **エラーハンドリング**
   - ネットワークエラー時の処理
   - 送金失敗時の処理
   - NWC接続エラー時の処理

### アーキテクチャ案

```
lib/
├── rust_bridge/          # flutter_rust_bridge関連
│   └── lightning_bridge.dart
├── services/
│   ├── nwc_service.dart  # NWC接続管理
│   └── lightning_service.dart  # Lightning送金処理
└── screens/
    └── settings_screen.dart  # NWC/Lightning設定画面

rust/
└── src/
    ├── lib.rs
    ├── nwc/
    │   └── client.rs
    └── lightning/
        └── payment.rs
```

## 📝 実装メモ

### 使用パッケージ

- **flutter_riverpod**: ^2.6.1 - 状態管理
- **alarm**: ^5.1.5 - アラーム機能
- **shared_preferences**: ^2.3.5 - ローカルストレージ
- **go_router**: ^14.6.4 - ルーティング
- **permission_handler**: ^11.3.1 - パーミッション管理
- **intl**: ^0.20.1 - 日時フォーマット

### 主要な設計判断

1. **alarmパッケージの採用理由**
   - 画面ロック解除機能が組み込み
   - 音声再生・バイブレーション対応
   - バックグラウンド動作
   - シンプルなAPI

2. **Riverpod 2.x の使用**
   - 最新の構文とベストプラクティスに準拠
   - Consumer のみを使用（ConsumerWidget は禁止）
   - UIとロジックの分離

3. **MVP アプローチ**
   - Repository層は未実装（必要になったら追加）
   - シンプルで保守しやすいコード
   - 段階的な機能追加

## 🐛 既知の問題

特になし

## 📚 参考資料

- [alarm package - pub.dev](https://pub.dev/packages/alarm)
- [Riverpod documentation](https://riverpod.dev/)
- [GoRouter documentation](https://pub.dev/packages/go_router)

