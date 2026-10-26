#!/bin/bash
# Package the most recently built AuraConnect.app into a shareable .dmg.
# Run on Mac:
#   ssh paul@192.168.1.106 'cat /home/paul/AuraConnect/package_dmg.sh' | bash
# Output: ~/Downloads/AuraConnect.dmg

set -e

APP=$(find ~/Library/Developer/Xcode/DerivedData \
  -name AuraConnect.app -path '*/Build/Products/Release/*' \
  -not -path '*Index.noindex*' -print 2>/dev/null | head -1)

if [ -z "$APP" ]; then
  APP=$(find ~/Library/Developer/Xcode/DerivedData \
    -name AuraConnect.app -path '*/Build/Products/*' \
    -not -path '*Index.noindex*' -print 2>/dev/null | head -1)
fi

if [ -z "$APP" ] || [ ! -d "$APP" ]; then
  echo "ERROR: No AuraConnect.app found in DerivedData. Build first."
  exit 1
fi

echo "==> Using $APP"

echo "==> Ad-hoc signing"
codesign --force --deep --sign - "$APP"

STAGE=/tmp/auradmg
DMG_OUT="$HOME/Downloads/AuraConnect.dmg"

echo "==> Staging"
rm -rf "$STAGE" "$DMG_OUT"
mkdir -p "$STAGE"
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"

echo "==> Creating .dmg"
hdiutil create \
  -volname "AuraConnect" \
  -srcfolder "$STAGE" \
  -ov \
  -format UDZO \
  "$DMG_OUT"

rm -rf "$STAGE"

echo
echo "============================================================"
echo "  DONE: $DMG_OUT"
echo "  Size: $(du -h "$DMG_OUT" | cut -f1)"
echo "============================================================"
echo "  Drag that file into Google Drive, share, send link."
echo "============================================================"
