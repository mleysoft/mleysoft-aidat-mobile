#!/bin/bash
set -euo pipefail

ROOT="${CM_BUILD_DIR:-$(pwd)}"
if [ -d "$ROOT/mobile_app" ]; then ROOT="$ROOT/mobile_app"; fi
cd "$ROOT"

echo "== MleySoft Codemagic iOS Post-build Guard =="

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

IPA="$(find build/ios "${CM_EXPORT_DIR:-/nonexistent}" -type f -name '*.ipa' 2>/dev/null | head -1 || true)"
APP=""

if [ -n "$IPA" ]; then
  unzip -q "$IPA" -d "$TMP/ipa"
  APP="$(find "$TMP/ipa/Payload" -maxdepth 1 -type d -name '*.app' | head -1 || true)"
fi

if [ -z "$APP" ]; then
  APP="$(find build/ios -type d -name '*.app' -path '*Products/Applications/*' | head -1 || true)"
fi

if [ -z "$APP" ] || [ ! -d "$APP" ]; then
  echo "ERROR: imzalanmış iOS .app bulunamadı; TestFlight yayını doğrulanamadı."
  exit 66
fi

NAME=$(/usr/libexec/PlistBuddy -c "Print :CFBundleDisplayName" "$APP/Info.plist" 2>/dev/null || true)
if [ "$NAME" != "MleySoft Aidat" ]; then
  echo "ERROR: Final IPA CFBundleDisplayName='$NAME'. Beklenen 'MleySoft Aidat'."
  exit 66
fi

if [ ! -f "$APP/GoogleService-Info.plist" ]; then
  echo "ERROR: Final IPA GoogleService-Info.plist içermiyor."
  exit 66
fi
FB_BUNDLE=$(/usr/libexec/PlistBuddy -c "Print :BUNDLE_ID" "$APP/GoogleService-Info.plist" 2>/dev/null || true)
if [ "$FB_BUNDLE" != "com.mleysoft.aidat" ]; then
  echo "ERROR: Final IPA Firebase bundle id yanlış: $FB_BUNDLE"
  exit 66
fi

PROFILE="$APP/embedded.mobileprovision"
if [ ! -f "$PROFILE" ]; then
  echo "ERROR: embedded.mobileprovision bulunamadı."
  exit 66
fi
security cms -D -i "$PROFILE" > "$TMP/profile.plist"
PROFILE_APS=$(/usr/libexec/PlistBuddy -c "Print :Entitlements:aps-environment" "$TMP/profile.plist" 2>/dev/null || true)
if [ "$PROFILE_APS" != "production" ]; then
  echo "ERROR: Codemagic App Store profile production APNs entitlement içermiyor. aps-environment='$PROFILE_APS'"
  exit 66
fi

codesign -d --entitlements :- "$APP" > "$TMP/codesign-entitlements.plist" 2>/dev/null || true
SIGNED_APS=$(/usr/libexec/PlistBuddy -c "Print :aps-environment" "$TMP/codesign-entitlements.plist" 2>/dev/null || true)
if [ "$SIGNED_APS" != "production" ]; then
  echo "ERROR: Final signed app production APNs entitlement içermiyor. aps-environment='$SIGNED_APS'"
  exit 66
fi

echo "FINAL IPA VERIFIED"
echo "  Name: $NAME"
echo "  Firebase bundle: $FB_BUNDLE"
echo "  Provisioning aps-environment: $PROFILE_APS"
echo "  Signed app aps-environment: $SIGNED_APS"
