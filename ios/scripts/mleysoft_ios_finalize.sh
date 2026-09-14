#!/bin/bash
set -euo pipefail

echo "========================================"
echo " MLEYSOFT AIDAT IOS FINALIZER V102"
echo "========================================"

VISIBLE_NAME=$'MleySoft\u00A0Aidat'
SRC_INFO="${SRCROOT}/Runner/Info.plist"
BUILT_INFO="${TARGET_BUILD_DIR}/${INFOPLIST_PATH}"
APP_DIR="${TARGET_BUILD_DIR}/${WRAPPER_NAME}"
GOOGLE_INFO="${SRCROOT}/Runner/GoogleService-Info.plist"

set_plist() {
  local file="$1" key="$2" value="$3"
  /usr/libexec/PlistBuddy -c "Set :${key} ${value}" "$file" 2>/dev/null || \
  /usr/libexec/PlistBuddy -c "Add :${key} string ${value}" "$file"
}

set_plist "$SRC_INFO" "CFBundleDisplayName" "$VISIBLE_NAME"
set_plist "$SRC_INFO" "CFBundleName" "$VISIBLE_NAME"

if [ -f "$BUILT_INFO" ]; then
  set_plist "$BUILT_INFO" "CFBundleDisplayName" "$VISIBLE_NAME"
  set_plist "$BUILT_INFO" "CFBundleName" "$VISIBLE_NAME"
fi

if [ -d "$APP_DIR" ]; then
  for LOC in tr en Base; do
    mkdir -p "${APP_DIR}/${LOC}.lproj"
    printf 'CFBundleDisplayName = "%s";\nCFBundleName = "%s";\n' "$VISIBLE_NAME" "$VISIBLE_NAME" > "${APP_DIR}/${LOC}.lproj/InfoPlist.strings"
  done
fi

if [ ! -f "$GOOGLE_INFO" ]; then
  echo "ERROR: GoogleService-Info.plist bulunamadi"
  exit 65
fi

FIREBASE_BUNDLE=$(/usr/libexec/PlistBuddy -c "Print :BUNDLE_ID" "$GOOGLE_INFO" 2>/dev/null || true)
if [ "$FIREBASE_BUNDLE" != "com.mleysoft.aidat" ]; then
  echo "ERROR: Firebase BUNDLE_ID=$FIREBASE_BUNDLE"
  exit 65
fi

if [ -d "$APP_DIR" ]; then
  cp "$GOOGLE_INFO" "${APP_DIR}/GoogleService-Info.plist"
fi

if [ "$CONFIGURATION" = "Release" ] || [ "$CONFIGURATION" = "Profile" ]; then
  APS=$(/usr/libexec/PlistBuddy -c "Print :aps-environment" "${SRCROOT}/Runner/Runner.entitlements" 2>/dev/null || true)
  if [ "$APS" != "production" ]; then
    echo "ERROR: Release/Profile aps-environment production degil: $APS"
    exit 65
  fi
fi

echo "FINALIZER OK"
echo "Visual name: MleySoft Aidat (NBSP)"
echo "Firebase bundle: $FIREBASE_BUNDLE"
