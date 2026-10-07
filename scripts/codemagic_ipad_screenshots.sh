#!/usr/bin/env bash
set -euo pipefail

ROOT="${CM_BUILD_DIR:-$(pwd)}"
cd "$ROOT"
if [[ -d mobile_app && -f mobile_app/pubspec.yaml ]]; then cd mobile_app; fi

log(){ printf '\n========== %s ==========\n' "$1"; }
fail(){ echo "ERROR: $1" >&2; exit 1; }

log "MLEYSOFT IPAD SCREENSHOTS V185"
rm -rf build/ipad_screenshots
mkdir -p build/ipad_screenshots
flutter pub get

# configure_ios.py sonrasındaki özel App Store projesi (AidatShare dahil) gerçek build için korunur.
# Flutter Drive tekrar pod install çalıştırdığı için bu özel pbxproj CocoaPods 1.16/xcodeproj ile
# ikinci kez parse edildiğinde çökebiliyor. Screenshot için temiz/geçici bir Simulator iOS projesi
# kullanıp işlem bittiğinde gerçek iOS klasörünü eksiksiz geri yüklüyoruz.
IOS_BACKUP="$(mktemp -d)/ios"
[[ -d ios ]] || fail "ios klasörü bulunamadı"
cp -a ios "$IOS_BACKUP"
IOS_PARENT="$(dirname "$IOS_BACKUP")"
RESTORED=0
UDID=""
restore_project(){
  set +e
  if [[ "$RESTORED" != "1" && -d "$IOS_BACKUP" ]]; then
    rm -rf ios
    cp -a "$IOS_BACKUP" ios
    RESTORED=1
  fi
  if [[ -n "${UDID:-}" ]]; then
    xcrun simctl shutdown "$UDID" >/dev/null 2>&1 || true
    xcrun simctl delete "$UDID" >/dev/null 2>&1 || true
  fi
  rm -rf "$IOS_PARENT" >/dev/null 2>&1 || true
}
trap restore_project EXIT

log "Geçici temiz iOS Simulator projesi hazırlanıyor"
rm -rf ios
flutter create --platforms=ios . >/tmp/mleysoft_flutter_create.log 2>&1 || {
  cat /tmp/mleysoft_flutter_create.log
  fail "Geçici iOS projesi oluşturulamadı"
}

# Screenshot build'inde imzalama/Share Extension gerekmez; gerçek proje birazdan geri gelecek.
# Minimum iOS sürümünü uygulamanın gerçek hedefiyle eşit tut.
python3 - <<'PY'
from pathlib import Path
p=Path('ios/Podfile')
if p.exists():
    s=p.read_text()
    if "platform :ios" in s:
        import re
        s=re.sub(r"platform :ios,\s*'[^']+'", "platform :ios, '15.0'", s)
    else:
        s="platform :ios, '15.0'\n"+s
    p.write_text(s)
PY

log "iPad Simulator seçiliyor"
RUNTIME=$(xcrun simctl list runtimes -j | python3 -c 'import json,sys; d=json.load(sys.stdin); a=[x for x in d["runtimes"] if x.get("isAvailable") and "iOS" in x.get("name","")]; print(a[-1]["identifier"] if a else "")')
DTYPE=$(xcrun simctl list devicetypes -j | python3 -c 'import json,sys; d=json.load(sys.stdin); a=[x for x in d["devicetypes"] if "iPad Air 11-inch" in x["name"] or "iPad Pro 13-inch" in x["name"]]; b=[x for x in d["devicetypes"] if "iPad" in x["name"]]; print((a[0] if a else b[-1])["identifier"] if (a or b) else "")')
[[ -n "$RUNTIME" ]] || fail "Kullanılabilir iOS Simulator runtime bulunamadı"
[[ -n "$DTYPE" ]] || fail "Kullanılabilir iPad Simulator device type bulunamadı"

UDID=$(xcrun simctl create "MleySoft AppStore iPad" "$DTYPE" "$RUNTIME")
xcrun simctl boot "$UDID"
open -a Simulator --args -CurrentDeviceUDID "$UDID" >/dev/null 2>&1 || true
xcrun simctl bootstatus "$UDID" -b

log "Flutter integration screenshot testi çalışıyor"
set +e
flutter drive \
  --no-pub \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/ipad_screenshots_test.dart \
  -d "$UDID"
DRIVE_STATUS=$?
set -e

# flutter drive sonucu ne olursa olsun gerçek iOS projesini build aşamasından ÖNCE geri getir.
restore_project
trap - EXIT

if [[ $DRIVE_STATUS -ne 0 ]]; then
  fail "iPad screenshot testi başarısız oldu (flutter drive exit: $DRIVE_STATUS)"
fi

COUNT=$(find build/ipad_screenshots -maxdepth 1 -type f -name '*.png' | wc -l | tr -d ' ')
[[ "$COUNT" -gt 0 ]] || fail "Screenshot testi tamamlandı ancak PNG üretilmedi"

log "IPAD SCREENSHOTS V185 HAZIR ($COUNT PNG)"
ls -lh build/ipad_screenshots/*.png
