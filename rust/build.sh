#!/bin/bash
set -e

# 色の定義
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# プロジェクトルートに移動
cd "$(dirname "$0")/.."

echo -e "${BLUE}🚀 Zap Clock - Rust Build Script${NC}"
echo ""

# cargo-ndkのチェック
if ! command -v cargo-ndk &> /dev/null; then
    echo -e "${RED}❌ cargo-ndk が見つかりません${NC}"
    echo -e "${YELLOW}以下のコマンドでインストールしてください:${NC}"
    echo "cargo install cargo-ndk"
    exit 1
fi

# ビルドモードの選択（引数で指定、デフォルトはdebug）
BUILD_MODE="${1:-debug}"

if [ "$BUILD_MODE" = "release" ]; then
    BUILD_FLAG="--release"
    echo -e "${GREEN}📦 リリースモードでビルドします${NC}"
else
    BUILD_FLAG=""
    echo -e "${GREEN}🔧 デバッグモードでビルドします${NC}"
fi

echo ""
echo -e "${BLUE}ステップ1: Flutter Rust Bridge コード生成${NC}"
flutter_rust_bridge_codegen generate

echo ""
echo -e "${BLUE}ステップ2: Android用Rustライブラリをビルド${NC}"
cd rust

# Android用ビルド（複数アーキテクチャ）
echo -e "${YELLOW}  📱 arm64-v8a をビルド中...${NC}"
cargo ndk -t arm64-v8a -o ../android/app/src/main/jniLibs build $BUILD_FLAG

echo -e "${YELLOW}  📱 armeabi-v7a をビルド中...${NC}"
cargo ndk -t armeabi-v7a -o ../android/app/src/main/jniLibs build $BUILD_FLAG

echo -e "${YELLOW}  💻 x86_64 をビルド中（エミュレータ用）...${NC}"
cargo ndk -t x86_64 -o ../android/app/src/main/jniLibs build $BUILD_FLAG

cd ..

echo ""
echo -e "${GREEN}✅ ビルド完了！${NC}"
echo ""
echo -e "${YELLOW}次のステップ:${NC}"
echo "  fvm flutter run    # アプリを実行"
echo ""
echo -e "${YELLOW}オプション:${NC}"
echo "  ./rust/build.sh           # デバッグビルド（デフォルト）"
echo "  ./rust/build.sh release   # リリースビルド（最適化あり）"

