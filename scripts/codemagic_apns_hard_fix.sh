#!/bin/bash
set -euo pipefail
cd "${CM_BUILD_DIR:-$(pwd)}"
if [ -d mobile_app ] && [ -f mobile_app/pubspec.yaml ]; then cd mobile_app; fi
echo '=== MLEYSOFT AIDAT CLEAN IOS PREBUILD / IK METHOD ==='
rm -rf ios
flutter create --platforms=ios --org com.mleysoft .
python3 native_config/configure_ios.py
flutter pub get
flutter build ios --config-only --release
test -f ios/Runner/GoogleService-Info.plist
/usr/libexec/PlistBuddy -c 'Print :BUNDLE_ID' ios/Runner/GoogleService-Info.plist | grep -q '^com.mleysoft.aidat$'
/usr/libexec/PlistBuddy -c 'Print :CFBundleDisplayName' ios/Runner/Info.plist | grep -q '^MleySoft Aidat$'
/usr/libexec/PlistBuddy -c 'Print :CFBundleName' ios/Runner/Info.plist | grep -q '^Runner$'
/usr/libexec/PlistBuddy -c 'Print :aps-environment' ios/Runner/Runner.entitlements | grep -q '^production$'
grep -q '^CODE_SIGN_ENTITLEMENTS=Runner/Runner.entitlements$' ios/Flutter/Release.xcconfig
grep -q 'CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;' ios/Runner.xcodeproj/project.pbxproj
grep -q 'GoogleService-Info.plist in Resources' ios/Runner.xcodeproj/project.pbxproj
grep -q 'Messaging.messaging().apnsToken=deviceToken' ios/Runner/AppDelegate.swift
grep -R -q 'MleySoftNativeBridgePlugin' ios/Runner/GeneratedPluginRegistrant.*
echo 'PREBUILD SUCCESS: fresh iOS + exact name + production APNs + native bridge'
