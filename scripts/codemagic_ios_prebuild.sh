#!/bin/bash
set -euo pipefail

ROOT="${CM_BUILD_DIR:-$(pwd)}"
if [ -d "$ROOT/mobile_app/ios" ]; then ROOT="$ROOT/mobile_app"; fi
cd "$ROOT"

echo "== MleySoft Codemagic iOS Pre-build =="

chmod +x ios/scripts/mleysoft_ios_finalize.sh
/usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName MleySoft Aidat" ios/Runner/Info.plist
/usr/libexec/PlistBuddy -c "Set :CFBundleName MleySoft Aidat" ios/Runner/Info.plist

BUNDLE=$(/usr/libexec/PlistBuddy -c "Print :BUNDLE_ID" ios/Runner/GoogleService-Info.plist)
if [ "$BUNDLE" != "com.mleysoft.aidat" ]; then
  echo "ERROR: GoogleService-Info.plist BUNDLE_ID=$BUNDLE"
  exit 65
fi

APS=$(/usr/libexec/PlistBuddy -c "Print :aps-environment" ios/Runner/RunnerRelease.entitlements)
if [ "$APS" != "production" ]; then
  echo "ERROR: RunnerRelease.entitlements production push içermiyor."
  exit 65
fi

echo "Pre-build OK: name, Firebase bundle and production APNs entitlement verified."
