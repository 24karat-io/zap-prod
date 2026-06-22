#!/bin/bash
# Writes the compile-time web build number used for stale-client detection.
set -euo pipefail

ROOT_DIR="${1:-..}"
FULL_VERSION=$(grep '^version:' "$ROOT_DIR/pubspec.yaml" | awk '{print $2}')
BUILD_NUMBER="${FULL_VERSION#*+}"

cat > "$ROOT_DIR/lib/shared/deploy_log.dart" <<EOF
/// Compile-time web build number baked in at deploy time.
/// Compared against [version.json] to detect stale cached JS bundles.
const deployBuildNumber = '$BUILD_NUMBER';
EOF

echo "Wrote deploy_log.dart (build $BUILD_NUMBER)"
