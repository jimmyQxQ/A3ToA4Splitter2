#!/bin/bash

# A3ToA4Splitter 构建脚本
# 用于在 macOS 上编译生成 IPA 文件

set -e

PROJECT_NAME="A3ToA4Splitter"
SCHEME_NAME="A3ToA4Splitter"
BUILD_DIR="build"

echo "================================"
echo "A3ToA4Splitter 构建脚本"
echo "================================"

# 检查是否在 macOS 上运行
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "错误: 此脚本需要在 macOS 上运行"
    exit 1
fi

# 检查 Xcode 是否安装
if ! command -v xcodebuild &> /dev/null; then
    echo "错误: 未找到 xcodebuild，请安装 Xcode"
    exit 1
fi

# 清理之前的构建
echo "清理之前的构建..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# 构建 Release 版本
echo "开始构建 Release 版本..."
xcodebuild -project "$PROJECT_NAME.xcodeproj" \
    -scheme "$SCHEME_NAME" \
    -configuration Release \
    -destination 'generic/platform=iOS' \
    -derivedDataPath "$BUILD_DIR/DerivedData" \
    clean build

# 查找生成的 app 文件
APP_PATH=$(find "$BUILD_DIR/DerivedData" -name "*.app" -type d | head -n 1)

if [ -z "$APP_PATH" ]; then
    echo "错误: 未找到生成的 .app 文件"
    exit 1
fi

echo "找到 app 文件: $APP_PATH"

# 创建 Payload 目录
echo "创建 Payload 目录..."
mkdir -p "$BUILD_DIR/Payload"
cp -R "$APP_PATH" "$BUILD_DIR/Payload/"

# 打包为 IPA
echo "打包为 IPA..."
cd "$BUILD_DIR"
zip -r "$PROJECT_NAME.ipa" Payload
cd ..

echo "================================"
echo "构建完成!"
echo "IPA 文件路径: $(pwd)/$BUILD_DIR/$PROJECT_NAME.ipa"
echo "================================"
echo ""
echo "安装说明:"
echo "1. 确保 iPhone 14 已安装巨魔工具 (TrollStore)"
echo "2. 将 IPA 文件传输到设备"
echo "3. 使用 TrollStore 打开并安装 IPA"
echo ""
