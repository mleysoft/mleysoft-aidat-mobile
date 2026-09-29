#!/bin/bash
set -euo pipefail

cd "${CM_BUILD_DIR:-$(pwd)}"
if [ -d "mobile_app" ] && [ -f "mobile_app/pubspec.yaml" ]; then
  cd mobile_app
fi

echo "========================================"
echo " MLEYSOFT AIDAT IOS PREBUILD V172"
echo "========================================"

echo "1) Repository iOS projesi ve Share Extension korunuyor..."
# V170'teki kritik hata: `rm -rf ios` + `flutter create` committed AidatShare target'ini siliyordu.
# Share Extension native Xcode target oldugu icin iOS klasoru CI sirasinda yeniden uretilmemelidir.
test -f ios/Runner.xcodeproj/project.pbxproj || { echo "ERROR: Repository iOS projesi bulunamadi"; exit 1; }
test -d ios/AidatShare || { echo "ERROR: AidatShare Share Extension repository'de bulunamadi"; exit 1; }
test -f ios/AidatShare/ShareViewController.swift || { echo "ERROR: AidatShare kaynak dosyasi eksik"; exit 1; }

echo "2) Flutter paketleri aliniyor..."
flutter pub get

echo "3) Aidat iOS ayarlari mevcut Xcode projesine uygulanıyor..."
python3 native_config/configure_ios.py

echo "4) Share Extension yapisi dogrulaniyor..."
test -f ios/AidatShare/Info.plist
test -f ios/AidatShare/AidatShare.entitlements
grep -q 'com.mleysoft.aidat.share' ios/Runner.xcodeproj/project.pbxproj
grep -q 'AidatShare.appex' ios/Runner.xcodeproj/project.pbxproj

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
# Firebase plist PBX comment is not a functional requirement; configure_ios.py may
# keep the resource under a normal PBXFileReference name. Verify the real file instead.
test -f ios/Runner/GoogleService-Info.plist

# Swift formatting can contain spaces around '='. Match semantically, not byte-for-byte.
grep -Eq 'Messaging\.messaging\(\)\.apnsToken[[:space:]]*=[[:space:]]*deviceToken' ios/Runner/AppDelegate.swift

test -f packages/mleysoft_native_bridge/ios/Classes/MleySoftNativeBridgePlugin.swift
grep -q 'registrar.addApplicationDelegate(instance)' packages/mleysoft_native_bridge/ios/Classes/MleySoftNativeBridgePlugin.swift
grep -q 'getNativePushTokens' packages/mleysoft_native_bridge/ios/Classes/MleySoftNativeBridgePlugin.swift
grep -q "s.dependency 'FirebaseMessaging'" packages/mleysoft_native_bridge/ios/mleysoft_native_bridge.podspec

echo ""
echo "########################################"
echo "PREBUILD SUCCESS V172"
echo " - Repository iOS project preserved"
echo " - Name = MS Aidat"
echo " - CFBundleName = Runner"
echo " - Bundle = com.mleysoft.aidat"
echo " - APNs entitlement source = production"
echo " - Native push bridge source = present"
echo " - AidatShare Share Extension preserved
 - NO signing/build command executed in Pre-build"
echo "########################################"
