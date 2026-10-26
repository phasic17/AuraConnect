#!/bin/bash
set -e
DEST="$HOME/Desktop/AuraConnect_2026-05-04"
echo "Killing any running AuraConnect…"
osascript -e 'quit app "AuraConnect"' 2>/dev/null || true
pkill -9 -x AuraConnect 2>/dev/null || true
sleep 1
sudo rm -rf "$DEST"
mkdir -p "$DEST"
rsync -rltv --delete --exclude build.sh paul@192.168.1.106:/home/paul/AuraConnect/ "$DEST/"
cd "$DEST"
xcodebuild -project AuraConnect.xcodeproj -scheme AuraConnect -configuration Debug -destination 'platform=macOS' build
APP="$(find ~/Library/Developer/Xcode/DerivedData -name AuraConnect.app -path '*/Build/Products/Debug/*' -not -path '*Index.noindex*' -print -quit)"
echo "Launching $APP"
open "$APP"
