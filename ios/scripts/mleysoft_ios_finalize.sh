#!/bin/bash
set -euo pipefail

echo "========================================"
echo " MLEYSOFT AIDAT IOS FINALIZER V103"
echo "========================================"

VISIBLE_NAME="MleySoft Aidat"
SRC_INFO="${SRCROOT}/Runner/Info.plist"
BUILT_INFO="${TARGET_BUILD_DIR}/${INFOPLIST_PATH}"
APP_DIR="${TARGET_BUILD_DIR}/${WRAPPER_NAME}"
GOOGLE_INFO="${SRCROOT}/Runner/GoogleService-Info.plist"

set_plist() {
  local file="$1" key="$2" value="$3"
  /usr/libexec/PlistBuddy -c "Set :${key} ${value}" "$file" 2>/dev/null || \
  /usr/libexec/PlistBuddy -c "Add :${key} string ${value}" "$file"
}

# Exact ASCII-space display name. CFBundleName remains Runner.
set_plist "$SRC_INFO" "CFBundleDisplayName" "$VISIBLE_NAME"
set_plist "$SRC_INFO" "CFBundleName" "Runner"
set_plist "$SRC_INFO" "NSPhotoLibraryUsageDescription" "Aidat ve site yönetimi işlemlerinde gerekli görselleri seçebilmeniz için fotoğraf arşivinize erişim gereklidir."

if [ -f "$BUILT_INFO" ]; then
  set_plist "$BUILT_INFO" "CFBundleDisplayName" "$VISIBLE_NAME"
  set_plist "$BUILT_INFO" "CFBundleName" "Runner"
  set_plist "$BUILT_INFO" "NSPhotoLibraryUsageDescription" "Aidat ve site yönetimi işlemlerinde gerekli görselleri seçebilmeniz için fotoğraf arşivinize erişim gereklidir."
fi


if [ -f "${APP_DIR}/Info.plist" ]; then
  set_plist "${APP_DIR}/Info.plist" "NSPhotoLibraryUsageDescription" "Aidat ve site yönetimi işlemlerinde gerekli görselleri seçebilmeniz için fotoğraf arşivinize erişim gereklidir."
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

APS=$(/usr/libexec/PlistBuddy -c "Print :aps-environment" "${SRCROOT}/Runner/Runner.entitlements" 2>/dev/null || true)
if [ "$APS" != "production" ]; then
  echo "ERROR: aps-environment production degil: $APS"
  exit 65
fi

echo "FINALIZER OK"
echo "Name: MleySoft Aidat"
echo "CFBundleName: Runner"
echo "Firebase bundle: $FIREBASE_BUNDLE"
