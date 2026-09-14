#!/bin/bash
set -euo pipefail
cd "${CM_BUILD_DIR:-$(pwd)}"
if [ -d mobile_app ] && [ -f mobile_app/pubspec.yaml ]; then cd mobile_app; fi
IPA=$(find build/ios/ipa -maxdepth 1 -name '*.ipa' -print -quit 2>/dev/null || true)
[ -n "$IPA" ] || { echo 'ERROR: IPA bulunamadi'; exit 1; }
TMP=/tmp/mleysoft_aidat_ipa_verify; rm -rf "$TMP"; mkdir -p "$TMP"; unzip -q "$IPA" -d "$TMP"
APP=$(find "$TMP/Payload" -maxdepth 1 -type d -name '*.app' -print -quit)
NAME=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleDisplayName' "$APP/Info.plist")
BN=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleName' "$APP/Info.plist")
BID=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$APP/Info.plist")
echo "FINAL NAME=[$NAME] BUNDLE_NAME=[$BN] BUNDLE=[$BID]"
[ "$NAME" = 'MleySoft Aidat' ] || { echo 'ERROR FINAL APP NAME'; exit 1; }
[ "$BN" = 'Runner' ] || { echo 'ERROR FINAL CFBundleName'; exit 1; }
[ "$BID" = 'com.mleysoft.aidat' ] || { echo 'ERROR FINAL BUNDLE'; exit 1; }
test -f "$APP/GoogleService-Info.plist"
FB=$(/usr/libexec/PlistBuddy -c 'Print :BUNDLE_ID' "$APP/GoogleService-Info.plist"); [ "$FB" = 'com.mleysoft.aidat' ]
codesign -d --entitlements :- "$APP" > "$TMP/ent.plist" 2>&1 || true
cat "$TMP/ent.plist"
grep -q '<key>aps-environment</key>' "$TMP/ent.plist"
grep -A1 '<key>aps-environment</key>' "$TMP/ent.plist" | grep -q production
grep -a -q 'getNativePushTokens' "$APP/Runner"
echo 'FINAL IPA SUCCESS: MleySoft Aidat / Runner / APNs production / native bridge present'
