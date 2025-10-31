#!/bin/bash
set -e

# 色の定義
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}🧹 Zap Clock - Clean Script${NC}"
echo ""

# Rust関連のクリーンアップ
if [ -d "rust/target" ]; then
    echo -e "${YELLOW}🗑️  Rustのbuildディレクトリをクリーンアップ中...${NC}"
    cd rust
    cargo clean
    cd ..
    echo -e "${GREEN}✅ Rustクリーンアップ完了${NC}"
fi

# Flutter関連のクリーンアップ
if [ -d "build" ]; then
    echo -e "${YELLOW}🗑️  Flutterのbuildディレクトリをクリーンアップ中...${NC}"
    fvm flutter clean
    echo -e "${GREEN}✅ Flutterクリーンアップ完了${NC}"
fi

# 生成されたJNIライブラリをクリーンアップ
if [ -d "android/app/src/main/jniLibs" ]; then
    echo -e "${YELLOW}🗑️  JNIライブラリをクリーンアップ中...${NC}"
    rm -rf android/app/src/main/jniLibs
    echo -e "${GREEN}✅ JNIライブラリクリーンアップ完了${NC}"
fi

echo ""
echo -e "${GREEN}✨ すべてのクリーンアップが完了しました！${NC}"
echo ""
echo -e "${YELLOW}次のステップ:${NC}"
echo "  ./build.sh          # 再ビルド"
echo "  fvm flutter pub get # 依存関係の再取得"





