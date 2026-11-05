#!/bin/bash
# Returns the next dev web build number by incrementing the live deploy on zap-dev.
set -euo pipefail

ROOT_DIR="${1:-..}"
REMOTE_URL="${2:-https://zap-dev.24karat.io/version.json}"

FULL_VERSION=$(grep '^version:' "$ROOT_DIR/pubspec.yaml" | awk '{print $2}')
PUBSPEC_BUILD="${FULL_VERSION#*+}"

if REMOTE_BUILD=$(curl -fsSL "$REMOTE_URL" | python3 -c "import sys, json; print(json.load(sys.stdin)['build_number'])"); then
  echo $((REMOTE_BUILD + 1))
else
  echo "Warning: could not fetch $REMOTE_URL, using pubspec build + 1 ($((PUBSPEC_BUILD + 1)))" >&2
  echo $((PUBSPEC_BUILD + 1))
fi
