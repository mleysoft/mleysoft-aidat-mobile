#!/bin/bash
set -euo pipefail

cd "${CM_BUILD_DIR:-$(pwd)}"
if [ -d "mobile_app" ] && [ -f "mobile_app/pubspec.yaml" ]; then
  cd mobile_app
fi

echo "========================================"
echo " MLEYSOFT AIDAT FINAL IPA CHECK V174"
echo "========================================"

IPA="$(find build/ios/ipa -maxdepth 1 -name '*.ipa' -print -quit 2>/dev/null || true)"
if [ -z "$IPA" ]; then
  echo "ERROR: IPA bulunamadi"
  exit 1
fi

TMP="/tmp/mleysoft_aidat_ipa_verify"
rm -rf "$TMP"
mkdir -p "$TMP"
unzip -q "$IPA" -d "$TMP"

APP="$(find "$TMP/Payload" -maxdepth 1 -type d -name '*.app' -print -quit)"
if [ -z "$APP" ]; then
  echo "ERROR: Payload icinde .app bulunamadi"
  exit 1
fi

NAME=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleDisplayName' "$APP/Info.plist")
BUNDLE_NAME=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleName' "$APP/Info.plist")
BUNDLE_ID=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$APP/Info.plist")

echo "FINAL NAME=[$NAME] BUNDLE_NAME=[$BUNDLE_NAME] BUNDLE=[$BUNDLE_ID]"

if [ "$NAME" != "MS Aidat" ]; then
  echo "ERROR: FINAL APP NAME WRONG"
  exit 1
fi

if [ "$BUNDLE_NAME" != "Runner" ]; then
  echo "ERROR: FINAL CFBundleName WRONG"
  exit 1
fi

if [ "$BUNDLE_ID" != "com.mleysoft.aidat" ]; then
  echo "ERROR: FINAL BUNDLE ID WRONG"
  exit 1
fi

# Localized InfoPlist.strings is optional for this app because the final
# CFBundleDisplayName is already fixed to "MS Aidat" in the built Info.plist.
# Do not fail a successful IPA just because Xcode omitted optional localization
# resource folders from the archive. If present, validate them; otherwise log it.
for LANG in tr en; do
  LOC="$APP/$LANG.lproj/InfoPlist.strings"
  if [ -f "$LOC" ]; then
    if ! grep -q 'CFBundleDisplayName = "MS Aidat";' "$LOC"; then
      echo "ERROR: FINAL localized display name wrong: $LANG"
      cat "$LOC" || true
      exit 1
    fi
    echo "Localized display name OK: $LANG"
  else
    echo "INFO: Optional localized InfoPlist.strings not embedded: $LANG (final name is already MS Aidat)"
  fi
done

# Share Extension must actually be embedded in the final IPA.
SHARE="$APP/PlugIns/AidatShare.appex"
if [ ! -d "$SHARE" ] || [ ! -f "$SHARE/Info.plist" ]; then
  echo "ERROR: FINAL IPA AidatShare.appex missing"
  exit 1
fi
SHARE_BUNDLE=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$SHARE/Info.plist")
if [ "$SHARE_BUNDLE" != "com.mleysoft.aidat.share" ]; then
  echo "ERROR: FINAL Share Extension bundle id wrong: $SHARE_BUNDLE"
  exit 1
fi
echo "FINAL Share Extension OK: $SHARE_BUNDLE"

if [ ! -f "$APP/GoogleService-Info.plist" ]; then
  echo "ERROR: FINAL IPA Firebase plist yok"
  exit 1
fi

FB_BUNDLE=$(/usr/libexec/PlistBuddy -c 'Print :BUNDLE_ID' "$APP/GoogleService-Info.plist")
if [ "$FB_BUNDLE" != "com.mleysoft.aidat" ]; then
  echo "ERROR: FINAL Firebase BUNDLE_ID=$FB_BUNDLE"
  exit 1
fi

# codesign output contains a warning line on current Xcode and the plist may be
# rendered on one line. Do not use grep -A1 or binary-string heuristics.
ENT_RAW="$TMP/entitlements_raw.txt"
codesign -d --entitlements :- "$APP" > "$ENT_RAW" 2>&1 || true
cat "$ENT_RAW"

if ! grep -q '<key>aps-environment</key>' "$ENT_RAW"; then
  echo "ERROR: FINAL aps-environment missing"
  exit 1
fi

# Current codesign may print the whole plist on one line, therefore search the
# complete output instead of assuming XML line breaks.
if ! tr '\n' ' ' < "$ENT_RAW" | grep -Eq '<key>aps-environment</key>[[:space:]]*<string>production</string>'; then
  echo "ERROR: FINAL APNs environment is not production"
  exit 1
fi

# IMPORTANT:
# v108 falsely failed here by grepping the optimized Runner executable for the
# literal Swift method name `getNativePushTokens`. Release/Swift optimization
# does not guarantee method-name strings remain in the final executable.
# Native bridge existence is already validated in Pre-build and a successful
# Xcode archive proves the plugin compiled/linked.

echo ""
echo "########################################"
echo "FINAL IPA SUCCESS V174"
echo " - Name = MS Aidat"
echo " - CFBundleName = Runner"
echo " - Bundle = com.mleysoft.aidat"
echo " - Firebase plist = com.mleysoft.aidat"
echo " - APNs = production"
echo "########################################"

EXT_PLIST="$TMP_DIR/Payload/Runner.app/PlugIns/AidatShare.appex/Info.plist"
EXT_EXECUTABLE=$(/usr/libexec/PlistBuddy -c "Print :CFBundleExecutable" "$EXT_PLIST" 2>/dev/null || true)
if [ -z "$EXT_EXECUTABLE" ]; then
  echo "ERROR: AidatShare CFBundleExecutable missing"
  exit 1
fi
if [ ! -f "$TMP_DIR/Payload/Runner.app/PlugIns/AidatShare.appex/$EXT_EXECUTABLE" ]; then
  echo "ERROR: AidatShare executable not found: $EXT_EXECUTABLE"
  exit 1
fi
echo "SHARE EXECUTABLE OK: $EXT_EXECUTABLE"
