#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
cd "$DIR"

echo "==> 正在编译 Release 版本..."
swift build -c release

APP_NAME="Reader"
APP_DIR="$DIR/dist/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "==> 正在打包 $APP_NAME.app..."
rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

cp "$DIR/.build/release/ReaderMac" "$MACOS_DIR/ReaderMac"
chmod +x "$MACOS_DIR/ReaderMac"

if [ -f "$DIR/scripts/Info.plist" ]; then
    cp "$DIR/scripts/Info.plist" "$CONTENTS_DIR/Info.plist"
fi

echo "✅ 打包完成！应用程序位于: $APP_DIR"
