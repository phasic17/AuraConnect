#!/bin/bash
# Build a release .dmg of AuraConnect for sharing.
#
# Run this on your Mac:
#   ssh paul@192.168.1.106 'cat /home/paul/AuraConnect/build_dmg.sh' | bash
#
# Output: ~/Desktop/AuraConnect.dmg (compressed disk image with the app + Applications shortcut)
#
# Note: this is an UNSIGNED build. When your friend opens it the first time
# they may see "AuraConnect can't be opened because Apple cannot check it
# for malicious software." Tell them to right-click the app -> Open, then
# click Open in the dialog. After that it launches normally.

set -e

DEST="$HOME/Desktop/AuraConnect_dmg_build"
STAGE="$HOME/Desktop/AuraConnect_dmg_stage"
# Land the final .dmg in ~/Downloads — that folder is always readable from
# Terminal regardless of macOS privacy gates and iCloud Desktop sync, so
# `ls`, curl, and Drive uploads all work without extra permissions.
DMG_OUT="$HOME/Downloads/AuraConnect.dmg"

echo "==> Quitting any running AuraConnect"
osascript -e 'quit app "AuraConnect"' 2>/dev/null || true
pkill -9 -x AuraConnect 2>/dev/null || true
sleep 1

echo "==> Syncing source from dev box"
sudo rm -rf "$DEST" "$STAGE" "$DMG_OUT"
mkdir -p "$DEST"
rsync -rlt --delete \
  --exclude build.sh --exclude build_dmg.sh \
  paul@192.168.1.106:/home/paul/AuraConnect/ "$DEST/"

echo "==> Building Release configuration"
cd "$DEST"
xcodebuild \
  -project AuraConnect.xcodeproj \
  -scheme AuraConnect \
  -configuration Release \
  -destination 'platform=macOS' \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  build

APP="$(find ~/Library/Developer/Xcode/DerivedData -name AuraConnect.app -path '*/Build/Products/Release/*' -not -path '*Index.noindex*' -print -quit)"
if [ -z "$APP" ] || [ ! -d "$APP" ]; then
  echo "ERROR: Could not find built AuraConnect.app in Release products"
  exit 1
fi
echo "    Built: $APP"

echo "==> Ad-hoc signing (lets it run on Apple Silicon without Gatekeeper hard-block)"
codesign --force --deep --sign - "$APP"

echo "==> Staging .dmg contents"
mkdir -p "$STAGE"
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"

echo "==> Creating compressed .dmg"
hdiutil create \
  -volname "AuraConnect" \
  -srcfolder "$STAGE" \
  -ov \
  -format UDZO \
  "$DMG_OUT"

echo
echo "==> Done — local DMG:  $DMG_OUT  ($(du -h "$DMG_OUT" | cut -f1))"

# ---- Optional: publish to GitHub Releases for an easy share link --------
# Requires `gh` (https://cli.github.com) authenticated against the AuraConnect
# repo. If unavailable, skip silently and just keep the local .dmg.
if command -v gh >/dev/null 2>&1; then
  TAG="auraconnect-$(date +%Y-%m-%d-%H%M)"
  TITLE="AuraConnect $(date +'%Y-%m-%d %H:%M')"
  NOTES="Latest AuraConnect build. Drag AuraConnect.app to Applications, then right-click → Open the first time (Gatekeeper)."

  # gh has to run inside the repo to know which one to publish to
  pushd "$DEST" >/dev/null

  echo "==> Publishing GitHub release $TAG"
  if gh release create "$TAG" "$DMG_OUT" \
      --title "$TITLE" \
      --notes "$NOTES" >/tmp/gh_release.out 2>&1; then
    REPO_SLUG="$(gh repo view --json nameWithOwner --jq .nameWithOwner)"
    PAGE_URL="https://github.com/$REPO_SLUG/releases/tag/$TAG"
    DIRECT_URL="https://github.com/$REPO_SLUG/releases/download/$TAG/AuraConnect.dmg"
    echo
    echo "============================================================"
    echo "  DIRECT DOWNLOAD LINK — send this to your friend:"
    echo
    echo "  $DIRECT_URL"
    echo
    echo "  Clicking it instantly downloads AuraConnect.dmg in their"
    echo "  browser — no GitHub login, no CLI, no extra clicks. They"
    echo "  open the .dmg, drag AuraConnect to Applications, done."
    echo "============================================================"
    echo "  (Release page if they want changelog / older builds:"
    echo "   $PAGE_URL )"
    echo "============================================================"
  else
    echo "    gh release failed — see /tmp/gh_release.out for details."
    echo "    Local .dmg is still at $DMG_OUT."
  fi
  popd >/dev/null
else
  echo
  echo "==> gh CLI not found — skipping GitHub release."
  echo "    To enable shareable links: brew install gh && gh auth login"
  echo "    For now, share $DMG_OUT via AirDrop / iMessage / Drive."
fi

echo
echo "First-time-open instructions for your friend:"
echo "  1. Open the .dmg, drag AuraConnect.app to Applications"
echo "  2. In Applications, right-click AuraConnect -> Open"
echo "  3. Click 'Open' in the Gatekeeper dialog (only required first time)"

# Cleanup intermediate dirs (leave the .dmg)
rm -rf "$STAGE"
