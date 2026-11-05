#!/bin/bash

# move to web folder
cd "$(dirname "$0")"
# configure environment
yes | cp dev/index.html .
yes | cp dev/manifest.json .
yes | cp dev/favicon.png .
yes | rm -rf icons
cp -R dev/icons .
# resolve next build number from live zap-dev deploy (pubspec.yaml unchanged)
NEXT_BUILD=$(bash next_dev_build_number.sh ..)
echo "Using dev build number $NEXT_BUILD"
bash write_deploy_log.sh .. "$NEXT_BUILD"
# move to project root folder
cd ..
VERSION_NAME=$(grep '^version:' pubspec.yaml | awk '{print $2}' | cut -d+ -f1)
# build web
yes | rm -rf release
flutter clean
flutter build web --release --output release/web --build-name="$VERSION_NAME" --build-number="$NEXT_BUILD"
bash web/patch_web_build.sh release/web
# push built result
git add -A
git commit -a -m "release new web"
git push -f