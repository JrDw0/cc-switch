#!/usr/bin/env bash
set -euo pipefail

# Tauri 增量快速打包脚本
#
# 原理：
# 1. cargo 自带增量编译，首次 ~6 分钟，后续改动通常 10-30s
# 2. Tauri v2 把前端资源（dist/）在编译时嵌入 Rust 二进制，
#    替换 binary 就等于替换整个 app，跳过 bundle (.app/.dmg) 阶段
# 3. 脚本会自动检测前端资源是否过期，按需 rebuild
#
# 首次使用：先跑一次完整 pnpm tauri build（生成 .app 模板）
# 后续改代码：跑这个脚本即可

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SRC_TAU_DIR="$SCRIPT_DIR/src-tauri"
APP="/Applications/CC Switch.app"
TARGET_BIN="$SRC_TAU_DIR/target/release/cc-switch"
DIST_DIR="$SCRIPT_DIR/dist"
VITE_CACHE="$SRC_TAU_DIR/target/release/build/cc-switch-*/out/.frontend-assets-hash"

if [ ! -d "$APP" ]; then
    echo "❌ 找不到 $APP"
    echo "   请先运行: pnpm tauri build"
    exit 1
fi

cd "$SCRIPT_DIR"

# 1. 前端资源：如果 dist/ 比目标 binary 旧，重跑 vite build
NEED_FE_BUILD=false
if [ ! -d "$DIST_DIR" ]; then
    NEED_FE_BUILD=true
elif [ -f "$TARGET_BIN" ]; then
    # dist 比 binary 新，说明前端改过
    newest_dist=$(find "$DIST_DIR" -type f -newer "$TARGET_BIN" 2>/dev/null | head -1)
    if [ -n "$newest_dist" ]; then
        NEED_FE_BUILD=true
    fi
else
    NEED_FE_BUILD=true
fi

if $NEED_FE_BUILD; then
    echo "📦 Building frontend..."
    pnpm --silent vite build
else
    echo "📦 Frontend up to date, skipping vite build."
fi

# 2. 增量编译 Rust 后端（cargo 自动复用上次缓存）
echo "🦀 Building Rust backend..."
cargo build --release --manifest-path "$SRC_TAU_DIR/Cargo.toml" --quiet

# 3. 关闭正在运行的 CC Switch
if pgrep -f "CC Switch.app" >/dev/null 2>&1; then
    echo "⏹  Closing running CC Switch..."
    osascript -e 'tell application "CC Switch" to quit' 2>/dev/null || true
    sleep 2
fi

# 4. 替换二进制
echo "📁 Replacing binary..."
cp -f "$TARGET_BIN" "$APP/Contents/MacOS/cc-switch"

# 5. 移除 Gatekeeper quarantine 标记（仅首次需要，后续是 no-op）
xattr -dr com.apple.quarantine "$APP" 2>/dev/null || true

echo "✅ Done!"
echo ""
echo "耗时对比："
echo "  完整 tauri build  : ~6 分钟（每次）"
echo "  这个脚本（增量）  : ~10-30 秒（仅重编译改动部分）"
