#!/bin/bash
set -e

# プロジェクトルートに移動
cd ..

# flutter_rust_bridgeのコード生成
echo "🔨 Generating Flutter Rust Bridge code..."

# 設定ファイルベースで生成
flutter_rust_bridge_codegen generate

echo "✅ Bridge code generated successfully!"

# Android用ビルド（必要に応じて）
echo "📦 Building Rust library for Android..."
# cargo ndk -t arm64-v8a -o ../android/app/src/main/jniLibs build --release

echo "🎉 Build complete!"
echo ""
echo "次のステップ:"
echo "1. Android用ビルド: cargo ndk -t arm64-v8a -o ../android/app/src/main/jniLibs build --release"
echo "2. Flutterアプリ実行: cd .. && fvm flutter run"

