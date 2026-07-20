#!/usr/bin/env bash
set -euo pipefail

# 本地快速构建并替换 CC Switch.app。
# 使用 Tauri debug profile，保留完整 App Bundle，避免直接替换裸二进制导致白屏。
# 适合日常开发测试；正式发布仍使用 pnpm tauri build。

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP="/Applications/CC Switch.app"
BUILT_APP="$SCRIPT_DIR/src-tauri/target/debug/bundle/macos/CC Switch.app"

cd "$SCRIPT_DIR"

echo "Building debug App bundle..."
pnpm tauri build --debug --bundles app

if [ ! -d "$BUILT_APP" ]; then
    echo "Build completed but App bundle was not found: $BUILT_APP" >&2
    exit 1
fi

if pgrep -f "/Applications/CC Switch.app/Contents/MacOS/cc-switch" >/dev/null 2>&1; then
    echo "Closing running CC Switch..."
    osascript -e 'tell application "CC Switch" to quit' 2>/dev/null || true
    sleep 2
fi

echo "Replacing $APP..."
rm -rf "$APP"
cp -R "$BUILT_APP" "/Applications/"
xattr -dr com.apple.quarantine "$APP" 2>/dev/null || true

echo "Launching CC Switch..."
open -a "$APP"
echo "Done."
