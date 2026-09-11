#!/bin/bash
set -euo pipefail

ROOT="${CM_BUILD_DIR:-$(pwd)}"
if [ -d "$ROOT/mobile_app/build" ]; then
    cd "$ROOT/mobile_app"
else
    cd "$ROOT"
fi

echo "========================================"
echo " MLEYSOFT AIDAT FINAL IOS/APNS CHECK"
echo "========================================"

APP="build/ios/archive/Runner.xcarchive/Products/Applications/Runner.app"

if [ ! -d "$APP" ]; then
    echo "ERROR: Runner.app bulunamadi"
    exit 1
fi

echo ""
echo "===== FINAL APP NAME ====="
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
echo "===== LOCALIZED APP NAME ====="
for LOC in tr en Base; do
    FILE="$APP/${LOC}.lproj/InfoPlist.strings"
    if [ ! -f "$FILE" ] || ! grep -Fq 'CFBundleDisplayName = "MleySoft Aidat";' "$FILE"; then
        echo "FAILED: $FILE icinde MleySoft Aidat yok"
        exit 1
    fi
done
echo "Localized names OK"

echo ""
echo "===== FINAL SIGNED ENTITLEMENTS ====="

ENTITLEMENTS=$(codesign -d --entitlements - "$APP" 2>&1 || true)
echo "$ENTITLEMENTS"

echo ""
echo "===== APNS CHECK ====="

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
echo "SUCCESS:"
echo " - APP NAME = MleySoft Aidat"
echo " - BUNDLE = com.mleysoft.aidat"
echo " - aps-environment = production"
echo " - Firebase plist = Aidat"
echo "########################################"
