#!/usr/bin/env bash
set -euo pipefail
cd "${CM_BUILD_DIR:-$(pwd)}"
# Codemagic proje kökü mobile_app değilse otomatik geç.
if [[ -d mobile_app && -f mobile_app/pubspec.yaml ]]; then cd mobile_app; fi

rm -rf build/ipad_screenshots
mkdir -p build/ipad_screenshots
flutter pub get

# Mevcut Xcode'daki en uygun iPad Simulator runtime/device type ile geçici cihaz oluştur.
RUNTIME=$(xcrun simctl list runtimes -j | python3 -c 'import json,sys; d=json.load(sys.stdin); a=[x for x in d["runtimes"] if x.get("isAvailable") and "iOS" in x.get("name","")]; print(a[-1]["identifier"] if a else "")')
DTYPE=$(xcrun simctl list devicetypes -j | python3 -c 'import json,sys; d=json.load(sys.stdin); a=[x for x in d["devicetypes"] if "iPad Pro 13-inch" in x["name"] or "iPad Air 11-inch" in x["name"]]; print((a[0] if a else [x for x in d["devicetypes"] if "iPad" in x["name"]][-1])["identifier"])')
if [[ -z "$RUNTIME" || -z "$DTYPE" ]]; then echo "ERROR: Kullanılabilir iOS/iPad Simulator bulunamadı"; exit 1; fi
UDID=$(xcrun simctl create "MleySoft AppStore iPad" "$DTYPE" "$RUNTIME")
trap 'xcrun simctl shutdown "$UDID" >/dev/null 2>&1 || true; xcrun simctl delete "$UDID" >/dev/null 2>&1 || true' EXIT
xcrun simctl boot "$UDID"
open -a Simulator --args -CurrentDeviceUDID "$UDID" || true
xcrun simctl bootstatus "$UDID" -b

# Gerçek iOS Simulator render'ı ile login + demo dashboard ekranlarını üret.
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/ipad_screenshots_test.dart \
  -d "$UDID"

echo "========================================"
echo "iPad screenshots hazır:"
ls -lh build/ipad_screenshots/*.png
echo "========================================"
