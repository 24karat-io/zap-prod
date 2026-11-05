#!/bin/bash
# Patches Flutter web build output so browsers fetch fresh entry assets after deploy.
set -euo pipefail

WEB_DIR="${1:-.}"
cd "$WEB_DIR"

if [ ! -f version.json ]; then
  echo "version.json not found in $(pwd)" >&2
  exit 1
fi

if [ ! -f index.html ]; then
  echo "index.html not found in $(pwd)" >&2
  exit 1
fi

VERSION=$(python3 -c "import json; print(json.load(open('version.json'))['version'])")
BUILD=$(python3 -c "import json; print(json.load(open('version.json'))['build_number'])")
APP_VERSION="${VERSION}+${BUILD}"

python3 - <<PY
import json
from datetime import datetime, timezone

with open("version.json") as f:
    data = json.load(f)

data["deploy_date"] = datetime.now(timezone.utc).strftime("%m/%d/%Y %I:%M:%S %p (UTC)")

with open("version.json", "w") as f:
    json.dump(data, f, separators=(",", ":"))
PY

# Cache-bust bootstrap loader and icon font references in index.html.
perl -pi -e "s|bootstrap_loader\\.js(\\?v=[^\"'\\s>]*)?|bootstrap_loader.js?v=${BUILD}|g" index.html
perl -pi -e "s|assets/assets/fonts/Ionicons\\.ttf(\\?v=[^\"'\\s>]*)?|assets/assets/fonts/Ionicons.ttf?v=${BUILD}|g" index.html

if grep -q 'name="app-version"' index.html; then
  perl -pi -e "s|<meta name=\"app-version\" content=\"[^\"]*\"|<meta name=\"app-version\" content=\"${APP_VERSION}\"|" index.html
else
  perl -pi -e "s|<meta charset=\"UTF-8\">|<meta charset=\"UTF-8\">\n  <meta name=\"app-version\" content=\"${APP_VERSION}\">|" index.html
fi

# Ensure main.dart.js is fetched with a build-specific URL (CanvasKit loader reads this).
if [ -f flutter_bootstrap.js ]; then
  perl -pi -e "s|\"mainJsPath\":\"main\\.dart\\.js(\\?v=[^\"]*)?\"|\"mainJsPath\":\"main.dart.js?v=${BUILD}\"|g" flutter_bootstrap.js
fi

if [ -f flutter.js ]; then
  perl -pi -e "s|\"mainJsPath\":\"main\\.dart\\.js(\\?v=[^\"]*)?\"|\"mainJsPath\":\"main.dart.js?v=${BUILD}\"|g" flutter.js
fi

echo "Patched web build ${APP_VERSION}"
