#!/bin/bash
set -euo pipefail

echo "========================================"
echo " MLEYSOFT AIDAT IOS FINALIZER"
echo "========================================"

SRC_INFO="${SRCROOT}/Runner/Info.plist"
BUILT_INFO="${TARGET_BUILD_DIR}/${INFOPLIST_PATH}"
APP_DIR="${TARGET_BUILD_DIR}/${WRAPPER_NAME}"
GOOGLE_INFO="${SRCROOT}/Runner/GoogleService-Info.plist"
BUILT_GOOGLE="${APP_DIR}/GoogleService-Info.plist"

set_plist() {
  local file="$1" key="$2" value="$3"
  /usr/libexec/PlistBuddy -c "Set :${key} ${value}" "$file" 2>/dev/null || \
  /usr/libexec/PlistBuddy -c "Add :${key} string ${value}" "$file"
}

# 1) Source and final built Info.plist both get the exact visible name.
set_plist "$SRC_INFO" "CFBundleDisplayName" "MleySoft Aidat"
set_plist "$SRC_INFO" "CFBundleName" "MleySoft Aidat"

if [ -f "$BUILT_INFO" ]; then
  set_plist "$BUILT_INFO" "CFBundleDisplayName" "MleySoft Aidat"
  set_plist "$BUILT_INFO" "CFBundleName" "MleySoft Aidat"
fi

# 2) Also create localized SpringBoard display-name overrides in the REAL .app.
# This prevents a generated/localized value from turning it back into MleySoftAidat.
if [ -d "$APP_DIR" ]; then
  for LOC in tr en Base; do
    mkdir -p "${APP_DIR}/${LOC}.lproj"
    cat > "${APP_DIR}/${LOC}.lproj/InfoPlist.strings" <<'EOF'
CFBundleDisplayName = "MleySoft Aidat";
CFBundleName = "MleySoft Aidat";
EOF
  done
fi

# 3) Firebase client file must belong to Aidat, not the IK app.
if [ ! -f "$GOOGLE_INFO" ]; then
  echo "ERROR: GoogleService-Info.plist bulunamadi"
  exit 65
fi

FIREBASE_BUNDLE=$(/usr/libexec/PlistBuddy -c "Print :BUNDLE_ID" "$GOOGLE_INFO" 2>/dev/null || true)
if [ "$FIREBASE_BUNDLE" != "com.mleysoft.aidat" ]; then
  echo "ERROR: Firebase BUNDLE_ID=$FIREBASE_BUNDLE, beklenen com.mleysoft.aidat"
  exit 65
fi

if [ -d "$APP_DIR" ]; then
  cp "$GOOGLE_INFO" "$BUILT_GOOGLE"
fi

# 4) TestFlight/App Store builds MUST use production entitlement.
if [ "$CONFIGURATION" = "Release" ] || [ "$CONFIGURATION" = "Profile" ]; then
  ENT="${SRCROOT}/Runner/Runner.entitlements"
  APS=$(/usr/libexec/PlistBuddy -c "Print :aps-environment" "$ENT" 2>/dev/null || true)
  if [ "$APS" != "production" ]; then
    echo "ERROR: Release/Profile aps-environment production degil: $APS"
    exit 65
  fi
fi

echo "FINALIZER OK"
echo "Name: MleySoft Aidat"
echo "Bundle: ${PRODUCT_BUNDLE_IDENTIFIER}"
echo "Firebase Bundle: ${FIREBASE_BUNDLE}"
