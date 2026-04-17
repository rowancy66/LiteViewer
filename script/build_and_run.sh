#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="LiteViewer"
BUNDLE_ID="com.liteviewer.app"
MIN_SYSTEM_VERSION="12.0"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_BINARY="$APP_MACOS/$APP_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"
TMP_HOME="$ROOT_DIR/.codex-home"
MODULE_CACHE_DIR="$ROOT_DIR/.build/module-cache"
CLANG_CACHE_DIR="$ROOT_DIR/.build/clang-module-cache"
ICON_SCRIPT_HOME="/tmp/liteviewer-icon-home"
ICON_MODULE_CACHE="/tmp/liteviewer-icon-module-cache"
ICON_CLANG_CACHE="/tmp/liteviewer-icon-clang-cache"

cd "$ROOT_DIR"
pkill -x "$APP_NAME" >/dev/null 2>&1 || true

mkdir -p \
  "$TMP_HOME/Library/Caches/org.swift.swiftpm" \
  "$TMP_HOME/Library/org.swift.swiftpm/configuration" \
  "$TMP_HOME/Library/org.swift.swiftpm/security" \
  "$MODULE_CACHE_DIR" \
  "$CLANG_CACHE_DIR" \
  "$ICON_SCRIPT_HOME" \
  "$ICON_MODULE_CACHE" \
  "$ICON_CLANG_CACHE"

export HOME="$TMP_HOME"
export SWIFTPM_MODULECACHE_OVERRIDE="$MODULE_CACHE_DIR"
export CLANG_MODULE_CACHE_PATH="$CLANG_CACHE_DIR"

HOME="$ICON_SCRIPT_HOME" \
SWIFTPM_MODULECACHE_OVERRIDE="$ICON_MODULE_CACHE" \
CLANG_MODULE_CACHE_PATH="$ICON_CLANG_CACHE" \
swift scripts/generate-app-icon.swift >/dev/null
swift build
BUILD_BINARY="$(find "$ROOT_DIR/.build" -path "*/debug/$APP_NAME" -type f | head -n 1)"

if [[ -z "$BUILD_BINARY" ]]; then
  echo "未找到构建产物：$APP_NAME" >&2
  exit 1
fi

rm -rf "$APP_BUNDLE"
mkdir -p "$APP_MACOS"
cp "$BUILD_BINARY" "$APP_BINARY"
chmod +x "$APP_BINARY"
cp "$ROOT_DIR/packaging/Info.plist" "$INFO_PLIST"
mkdir -p "$APP_CONTENTS/Resources"
cp "$ROOT_DIR/packaging/AppIcon.icns" "$APP_CONTENTS/Resources/AppIcon.icns"

if ! /usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$INFO_PLIST" >/dev/null 2>&1; then
  /usr/libexec/PlistBuddy -c "Add :CFBundleIdentifier string $BUNDLE_ID" "$INFO_PLIST"
else
  /usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $BUNDLE_ID" "$INFO_PLIST"
fi

if ! /usr/libexec/PlistBuddy -c "Print :LSMinimumSystemVersion" "$INFO_PLIST" >/dev/null 2>&1; then
  /usr/libexec/PlistBuddy -c "Add :LSMinimumSystemVersion string $MIN_SYSTEM_VERSION" "$INFO_PLIST"
else
  /usr/libexec/PlistBuddy -c "Set :LSMinimumSystemVersion $MIN_SYSTEM_VERSION" "$INFO_PLIST"
fi

open_app() {
  /usr/bin/open -n "$APP_BUNDLE"
}

case "$MODE" in
  run)
    open_app
    ;;
  --debug|debug)
    lldb -- "$APP_BINARY"
    ;;
  --logs|logs)
    open_app
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  --telemetry|telemetry)
    open_app
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  --verify|verify)
    open_app
    sleep 1
    pgrep -x "$APP_NAME" >/dev/null
    ;;
  *)
    echo "usage: $0 [run|--debug|--logs|--telemetry|--verify]" >&2
    exit 2
    ;;
esac
