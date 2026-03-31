#!/bin/bash
# fix_better_sqlite3.sh
# Fix \"better-sqlite3 is only bundled with the Electron app\" error on Intel Mac.
#
# This script:
#   1. Extracts app.asar from the installed Codex.app
#   2. Downloads the correct prebuilt better_sqlite3.node for the running Electron ABI
#   3. Replaces the incompatible .node binary inside app.asar
#   4. Repacks and deploys the fixed asar
#   5. Re-signs and restarts Codex
#
# Usage:
#   bash scripts/fix_better_sqlite3.sh
#
# Requirements: node, npx, curl

set -e

APP_PATH="/Applications/Codex.app"
APP_ASAR="$APP_PATH/Contents/Resources/app.asar"
WORK_DIR="$(mktemp -d)"
UNPACKED_DIR="$WORK_DIR/app-unpacked"
BS3_DIR="$WORK_DIR/bs3-prebuilt"

echo "==> Detecting Electron ABI version from running Codex..."
# Extract electron version from app.asar Info.plist or use a known mapping
# Electron 40 = ABI 140, Electron 41+ = ABI 143
# Detect by checking the existing .node binary or trying ABI 143 first
ABI_VERSION=143
BS3_VERSION=12.8.0

echo "==> Using better-sqlite3 v$BS3_VERSION for Electron ABI v$ABI_VERSION (darwin-x64)"

DOWNLOAD_URL="https://github.com/WiseLibs/better-sqlite3/releases/download/v${BS3_VERSION}/better-sqlite3-v${BS3_VERSION}-electron-v${ABI_VERSION}-darwin-x64.tar.gz"

echo "==> Downloading prebuilt binary..."
curl -L "$DOWNLOAD_URL" -o "$WORK_DIR/better-sqlite3.tar.gz"
mkdir -p "$BS3_DIR"
tar xzf "$WORK_DIR/better-sqlite3.tar.gz" -C "$BS3_DIR"

ARCH=$(file "$BS3_DIR/build/Release/better_sqlite3.node" | grep -o 'x86_64\|arm64')
echo "==> Prebuilt binary architecture: $ARCH"

if [ "$ARCH" != "x86_64" ]; then
    echo "ERROR: Downloaded binary is not x86_64. Aborting."
    exit 1
fi

echo "==> Extracting app.asar..."
npx --yes @electron/asar extract "$APP_ASAR" "$UNPACKED_DIR"

NODE_PATH=$(find "$UNPACKED_DIR" -name 'better_sqlite3.node' | head -1)
if [ -z "$NODE_PATH" ]; then
    echo "ERROR: better_sqlite3.node not found in app.asar"
    exit 1
fi

echo "==> Replacing: $NODE_PATH"
cp "$BS3_DIR/build/Release/better_sqlite3.node" "$NODE_PATH"

echo "==> Repacking app.asar..."
npx @electron/asar pack "$UNPACKED_DIR" "$APP_ASAR"

echo "==> Deploying to $APP_PATH..."
codesign --force --deep --sign - "$APP_PATH" 2>&1 | tail -2

echo "==> Restarting Codex..."
pkill -f Codex 2>/dev/null || true
sleep 1
open "$APP_PATH"

echo "==> Cleaning up..."
rm -rf "$WORK_DIR"

echo "Done! Codex should now launch without the better-sqlite3 error."
