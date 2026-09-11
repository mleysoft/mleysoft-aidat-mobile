#!/bin/sh
set -eu

echo "== MleySoft iOS Finalizer =="

SOURCE_INFO="${SRCROOT}/Runner/Info.plist"
BUILT_INFO="${TARGET_BUILD_DIR}/${INFOPLIST_PATH}"
GOOGLE_INFO="${SRCROOT}/Runner/GoogleService-Info.plist"
BUILT_GOOGLE="${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/GoogleService-Info.plist"

set_plist_value() {
  file="$1"
  key="$2"
  value="$3"
  /usr/libexec/PlistBuddy -c "Set :${key} ${value}" "$file" 2>/dev/null || \
    /usr/libexec/PlistBuddy -c "Add :${key} string ${value}" "$file"
}

# Source plist and the actual app bundle plist are both forced.
if [ -f "$SOURCE_INFO" ]; then
  set_plist_value "$SOURCE_INFO" "CFBundleDisplayName" "MleySoft Aidat"
  set_plist_value "$SOURCE_INFO" "CFBundleName" "MleySoft Aidat"
fi
if [ -f "$BUILT_INFO" ]; then
  set_plist_value "$BUILT_INFO" "CFBundleDisplayName" "MleySoft Aidat"
  set_plist_value "$BUILT_INFO" "CFBundleName" "MleySoft Aidat"
fi

# Firebase configuration must belong to this exact iOS bundle.
if [ ! -f "$GOOGLE_INFO" ]; then
  echo "ERROR: GoogleService-Info.plist bulunamadı."
  exit 65
fi
FIREBASE_BUNDLE=$(/usr/libexec/PlistBuddy -c "Print :BUNDLE_ID" "$GOOGLE_INFO" 2>/dev/null || true)
if [ "$FIREBASE_BUNDLE" != "com.mleysoft.aidat" ]; then
  echo "ERROR: Firebase BUNDLE_ID yanlış: $FIREBASE_BUNDLE"
  exit 65
fi
mkdir -p "$(dirname "$BUILT_GOOGLE")"
cp "$GOOGLE_INFO" "$BUILT_GOOGLE"

# Source entitlements are re-asserted immediately before Xcode signing.
if [ "$CONFIGURATION" = "Release" ] || [ "$CONFIGURATION" = "Profile" ]; then
  ENT="${SRCROOT}/Runner/RunnerRelease.entitlements"
  EXPECTED_APS="production"
else
  ENT="${SRCROOT}/Runner/Runner.entitlements"
  EXPECTED_APS="development"
fi
ACTUAL_APS=$(/usr/libexec/PlistBuddy -c "Print :aps-environment" "$ENT" 2>/dev/null || true)
if [ "$ACTUAL_APS" != "$EXPECTED_APS" ]; then
  echo "ERROR: aps-environment $EXPECTED_APS olmalı, bulunan: $ACTUAL_APS"
  exit 65
fi

# If Codemagic has already embedded the provisioning profile at this point,
# validate it too. If it is copied later, the post-build guard handles it.
PROFILE="${TARGET_BUILD_DIR}/${WRAPPER_NAME}/embedded.mobileprovision"
if [ -f "$PROFILE" ]; then
  TMP_PROFILE="${TEMP_DIR}/mleysoft_profile.plist"
  security cms -D -i "$PROFILE" > "$TMP_PROFILE" 2>/dev/null || true
  PROFILE_APS=$(/usr/libexec/PlistBuddy -c "Print :Entitlements:aps-environment" "$TMP_PROFILE" 2>/dev/null || true)
  if [ "$CONFIGURATION" = "Release" ] && [ "$PROFILE_APS" != "production" ]; then
    echo "ERROR: App Store/TestFlight provisioning profile Push Notifications production entitlement içermiyor."
    exit 65
  fi
fi

echo "CFBundleDisplayName: MleySoft Aidat"
echo "Firebase BUNDLE_ID: $FIREBASE_BUNDLE"
echo "aps-environment source: $EXPECTED_APS"
