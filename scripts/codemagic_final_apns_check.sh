#!/bin/bash
set -euo pipefail

ROOT="${CM_BUILD_DIR:-$(pwd)}"
if [ -d "$ROOT/mobile_app" ]; then
    cd "$ROOT/mobile_app"
else
    cd "$ROOT"
fi

echo "========================================"
echo " MLEYSOFT AIDAT FINAL IOS/APNS CHECK"
echo "========================================"

APP=""
CANDIDATES=(
  "build/ios/archive/Runner.xcarchive/Products/Applications/Runner.app"
  "build/ios/iphoneos/Runner.app"
)
for C in "${CANDIDATES[@]}"; do
    if [ -d "$C" ]; then APP="$C"; break; fi
done

if [ -z "$APP" ]; then
    APP="$(find build/ios -type d -path '*/Products/Applications/Runner.app' -print -quit 2>/dev/null || true)"
fi

if [ -z "$APP" ] || [ ! -d "$APP" ]; then
    echo "ERROR: Final Runner.app bulunamadi"
    find build/ios -type d -name '*.app' 2>/dev/null || true
    exit 1
fi

echo "Final app: $APP"

NAME=$(/usr/libexec/PlistBuddy -c "Print :CFBundleDisplayName" "$APP/Info.plist" 2>/dev/null || true)
BUNDLE=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$APP/Info.plist" 2>/dev/null || true)
echo "CFBundleDisplayName = $NAME"
echo "CFBundleIdentifier = $BUNDLE"

if [ "$NAME" != "MleySoft Aidat" ]; then
    echo "FAILED: final app adi MleySoft Aidat degil"
    exit 1
fi
if [ "$BUNDLE" != "com.mleysoft.aidat" ]; then
    echo "FAILED: final bundle id com.mleysoft.aidat degil"
    exit 1
fi

echo ""
echo "===== FINAL SIGNED ENTITLEMENTS ====="
ENTITLEMENTS=$(codesign -d --entitlements - "$APP" 2>&1 || true)
echo "$ENTITLEMENTS"

if ! echo "$ENTITLEMENTS" | grep -Fq "aps-environment"; then
    echo "FAILED: aps-environment FINAL APP'TE YOK"
    exit 1
fi
if ! echo "$ENTITLEMENTS" | grep -Fq "production"; then
    echo "FAILED: FINAL APP aps-environment production DEGIL"
    exit 1
fi

echo ""
echo "===== FIREBASE CHECK ====="
if [ ! -f "$APP/GoogleService-Info.plist" ]; then
    echo "FAILED: final app GoogleService-Info.plist icermiyor"
    exit 1
fi
FB_BUNDLE=$(/usr/libexec/PlistBuddy -c "Print :BUNDLE_ID" "$APP/GoogleService-Info.plist" 2>/dev/null || true)
echo "Firebase BUNDLE_ID = $FB_BUNDLE"
if [ "$FB_BUNDLE" != "com.mleysoft.aidat" ]; then
    echo "FAILED: Firebase bundle id Aidat degil"
    exit 1
fi

echo ""
echo "########################################"
echo "SUCCESS: FINAL IOS BUILD DOGRULANDI"
echo " - APP NAME = MleySoft Aidat"
echo " - BUNDLE = com.mleysoft.aidat"
echo " - aps-environment = production"
echo " - Firebase plist = Aidat"
echo "########################################"
