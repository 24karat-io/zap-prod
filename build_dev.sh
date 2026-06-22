#!/bin/bash

# move to web folder
cd "$(dirname "$0")"
# configure environment
yes | cp dev/index.html .
yes | cp dev/manifest.json .
yes | rm -rf icons
cp -R dev/icons .
# generate version time log
bash write_deploy_log.sh ..
# move to project root folder
cd ..
# build web
yes | rm -rf release
flutter clean
flutter build web --release --output release/web
bash web/patch_web_build.sh release/web
# push built result
git add -A
git commit -a -m "release new web"
git push -f