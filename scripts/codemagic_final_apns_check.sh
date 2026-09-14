#!/bin/bash
set -euo pipefail

ROOT="${CM_BUILD_DIR:-$(pwd)}"
if [ -d "$ROOT/mobile_app" ]; then cd "$ROOT/mobile_app"; else cd "$ROOT"; fi

echo "========================================"
echo " MLEYSOFT AIDAT FINAL APNS CHECK"
echo "========================================"

APP="build/ios/archive/Runner.xcarchive/Products/Applications/Runner.app"
if [ ! -d "$APP" ]; then
  APP="$(find build/ios -type d -path '*/Products/Applications/Runner.app' -print -quit 2>/dev/null || true)"
fi
if [ -z "$APP" ] || [ ! -d "$APP" ]; then
  echo "ERROR: Runner.app bulunamadi"
  exit 1
fi

echo "===== FINAL NAME ====="
NAME=$(/usr/libexec/PlistBuddy -c "Print :CFBundleDisplayName" "$APP/Info.plist" 2>/dev/null || true)
echo "CFBundleDisplayName=$NAME"
[ "$NAME" = "MleySoft Aidat" ] || { echo "ERROR: final app adi MleySoft Aidat degil"; exit 1; }

echo ""
echo "===== FINAL SIGNED ENTITLEMENTS ====="
ENTITLEMENTS=$(codesign -d --entitlements - "$APP" 2>&1 || true)
echo "$ENTITLEMENTS"

echo ""
echo "===== CHECK ====="
if echo "$ENTITLEMENTS" | grep -Fq "aps-environment" &&
   echo "$ENTITLEMENTS" | grep -Fq "production"; then
  echo "SUCCESS: aps-environment FINAL APP'TE PRODUCTION"
else
  echo "FAILED: final signed app production aps-environment icermiyor"
  exit 1
fi

test -f "$APP/GoogleService-Info.plist" || { echo "ERROR: final app Firebase plist icermiyor"; exit 1; }
FB=$(/usr/libexec/PlistBuddy -c "Print :BUNDLE_ID" "$APP/GoogleService-Info.plist" 2>/dev/null || true)
[ "$FB" = "com.mleysoft.aidat" ] || { echo "ERROR: Firebase plist bundle=$FB"; exit 1; }

echo ""
echo "########################################"
echo "SUCCESS: FINAL AIDAT IOS BUILD"
echo " - Name = MleySoft Aidat"
echo " - APNs = production"
echo " - Firebase = com.mleysoft.aidat"
echo "########################################"
