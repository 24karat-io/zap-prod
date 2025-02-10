#!/bin/bash

# move to web folder
cd "$(dirname "$0")"
# configure environment
yes | cp dev/index.html .
yes | cp dev/manifest.json .
yes | rm -rf icons
cp -R dev/icons .
# generate version time log
NOW=$(date +"%m/%d/%Y %r (%Z)")
echo "const deployDate = '$NOW';" > ../lib/shared/deploy_log.dart
# move to project root folder
cd ..
# build web
yes | rm -rf release
flutter clean
flutter build web --wasm --output release/web
# push built result
git add -A
git commit -a -m "release new web"
git push -f