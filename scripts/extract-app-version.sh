#!/bin/bash
#
# Script: extract-app-version.sh
# Description: Extracts version information from Codex.app
#
# Usage: ./scripts/extract-app-version.sh <path-to-codex-dmg>
#
# Requirements: macOS, hdiutil, defaults
#
# Output: JSON with version information
# Example: {"version": "0.8.0", "electron": "40.0.0", "build_date": "2025-03-22"}
#

set -e

DMG_PATH="${1:-Codex.dmg}"

if [[ ! -f "$DMG_PATH" ]]; then
  echo "Error: DMG file not found at: $DMG_PATH" >&2
  exit 1
fi

# Create temporary mount point
MOUNT_POINT="/tmp/codex_extract_$$"
mkdir -p "$MOUNT_POINT"

# Mount the DMG (noverify for speed, nobrowse to avoid Finder)
hdiutil attach -noverify -nobrowse -mountpoint "$MOUNT_POINT" "$DMG_PATH" > /dev/null 2>&1

# Check if mount was successful
if [[ ! -d "$MOUNT_POINT/Codex.app" ]]; then
  echo "Error: Failed to mount DMG or Codex.app not found" >&2
  hdiutil detach "$MOUNT_POINT" > /dev/null 2>&1 || true
  rmdir "$MOUNT_POINT" 2>/dev/null || true
  exit 1
fi

# Extract version from Info.plist
CODEX_VERSION=$(defaults read "$MOUNT_POINT/Codex.app/Contents/Info.plist" CFBundleShortVersionString 2>/dev/null || echo "unknown")
ELECTRON_VERSION=$(defaults read "$MOUNT_POINT/Codex.app/Contents/Info.plist" CFBundleVersion 2>/dev/null || echo "unknown")

# Clean up
hdiutil detach "$MOUNT_POINT" > /dev/null 2>&1
rmdir "$MOUNT_POINT" 2>/dev/null || true

# Sanitize version strings
CODEX_VERSION="${CODEX_VERSION//[^a-zA-Z0-9.-]/}"
ELECTRON_VERSION="${ELECTRON_VERSION//[^a-zA-Z0-9.-]/}"

# Fallback to date-based if extraction failed
if [[ "$CODEX_VERSION" == "unknown" ]] || [[ -z "$CODEX_VERSION" ]]; then
  CODEX_VERSION=$(date +"%Y.%m.%d")
fi

# Output JSON
BUILD_DATE=$(date +"%Y-%m-%d")
cat <<EOF
{
  "version": "$CODEX_VERSION",
  "electron": "$ELECTRON_VERSION",
  "build_date": "$BUILD_DATE"
}
EOF