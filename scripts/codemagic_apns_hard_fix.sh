#!/bin/bash
set -euo pipefail

cd "${CM_BUILD_DIR:-$(pwd)}"
if [ -d "mobile_app" ] && [ -f "mobile_app/pubspec.yaml" ]; then
  cd mobile_app
fi

echo "========================================"
echo " MLEYSOFT AIDAT CLEAN IOS PREBUILD V114"
echo "========================================"

echo "1) Eski iOS klasoru siliniyor..."
rm -rf ios

echo "2) Flutter standart iOS platformu yeniden olusturuluyor..."
flutter create --platforms=ios --org com.mleysoft .

echo "3) Aidat iOS ayarlari uygulanıyor..."
python3 native_config/configure_ios.py

echo "4) Flutter paketleri aliniyor..."
flutter pub get

# IMPORTANT:
# Workflow Editor Pre-build, Codemagic'in `xcode-project use-profiles`
# adimindan ONCE calisir. Bu nedenle burada `flutter build ios`,
# `flutter build ipa` veya herhangi bir signing isteyen Xcode build
# KESINLIKLE calistirilmaz.
#
# Native plugin registration/pod install asıl "Building iOS" adiminda,
# Codemagic provisioning profile ve Apple Distribution sertifikasini
# bagladiktan sonra otomatik yapilir.

echo "5) Signing gerektirmeyen kaynak kontrolleri..."

test -f ios/Runner/GoogleService-Info.plist
/usr/libexec/PlistBuddy -c 'Print :BUNDLE_ID' ios/Runner/GoogleService-Info.plist | grep -q '^com.mleysoft.aidat$'

/usr/libexec/PlistBuddy -c 'Print :CFBundleDisplayName' ios/Runner/Info.plist | grep -q '^MS Aidat$'
/usr/libexec/PlistBuddy -c 'Print :CFBundleName' ios/Runner/Info.plist | grep -q '^Runner$'

test -f ios/Runner/Runner.entitlements
/usr/libexec/PlistBuddy -c 'Print :aps-environment' ios/Runner/Runner.entitlements | grep -q '^production$'

grep -q '^CODE_SIGN_ENTITLEMENTS=Runner/Runner.entitlements$' ios/Flutter/Release.xcconfig
grep -q 'CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;' ios/Runner.xcodeproj/project.pbxproj
grep -q 'MleySoft Firebase Plist' ios/Runner.xcodeproj/project.pbxproj

grep -q 'Messaging.messaging().apnsToken=deviceToken' ios/Runner/AppDelegate.swift

test -f packages/mleysoft_native_bridge/ios/Classes/MleySoftNativeBridgePlugin.swift
grep -q 'registrar.addApplicationDelegate(instance)' packages/mleysoft_native_bridge/ios/Classes/MleySoftNativeBridgePlugin.swift
grep -q 'getNativePushTokens' packages/mleysoft_native_bridge/ios/Classes/MleySoftNativeBridgePlugin.swift
grep -q "s.dependency 'FirebaseMessaging'" packages/mleysoft_native_bridge/ios/mleysoft_native_bridge.podspec

echo ""
echo "########################################"
echo "PREBUILD SUCCESS V114"
echo " - iOS fresh generated"
echo " - Name = MS Aidat"
echo " - CFBundleName = Runner"
echo " - Bundle = com.mleysoft.aidat"
echo " - APNs entitlement source = production"
echo " - Native push bridge source = present"
echo " - NO signing/build command executed in Pre-build"
echo "########################################"
