#!/bin/bash
#
# Script: get-last-dmg-hash.sh
# Description: Extracts the SHA256 hash from the last Intel release's notes
#
# Usage: ./scripts/get-last-dmg-hash.sh [repo-owner] [repo-name]
#
# Output format: <hash> or "none"
#
# Example: ./scripts/get-last-dmg-hash.sh soham2008xyz codex-rebuilder
#

set -e

# Get repository info from arguments or default to current repo
REPO_OWNER="${1:-${GITHUB_REPOSITORY_OWNER}}"
REPO_NAME="${2:-${GITHUB_REPOSITORY##*/}}"
REPO="${REPO_OWNER}/${REPO_NAME}"

# Check if gh CLI is available
if ! command -v gh &> /dev/null; then
  echo "none"
  exit 0
fi

# Get the latest Intel release
LATEST_RELEASE=$(gh release list --limit 20 --json tagName,body --jq ".[] | select(.tagName | test(\"-intel$$\")) | .tagName" 2>/dev/null | head -n1 || echo "")

if [[ -z "$LATEST_RELEASE" ]]; then
  echo "none"
  exit 0
fi

# Extract DMG hash from release notes
DMG_HASH=$(gh release view "$LATEST_RELEASE" --json body --jq '.body' 2>/dev/null | grep -i "DMG SHA256" | grep -oE '[a-f0-9]{64}' || echo "")

if [[ -n "$DMG_HASH" ]]; then
  echo "$DMG_HASH"
else
  echo "none"
fi