#!/usr/bin/env bash
set -euo pipefail

ROOT="${CM_BUILD_DIR:-$(pwd)}"
cd "$ROOT"
if [[ -d mobile_app && -f mobile_app/pubspec.yaml ]]; then cd mobile_app; fi

log(){ printf '\n========== %s ==========\n' "$1"; }
fail(){ echo "ERROR: $1" >&2; exit 1; }

log "MLEYSOFT IPAD SCREENSHOT V187 - SIMCTL DIRECT"
rm -rf build/ipad_screenshots
mkdir -p build/ipad_screenshots
flutter pub get

# Gerçek App Store iOS projesi (AidatShare dahil) asla değiştirilmez.
# Screenshot için geçici temiz iOS Simulator projesi kullanılır ve sonunda gerçek proje geri yüklenir.
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

python3 - <<'PY'
from pathlib import Path
p=Path('ios/Podfile')
if p.exists():
    s=p.read_text()
    import re
    if "platform :ios" in s:
        s=re.sub(r"platform :ios,\s*'[^']+'", "platform :ios, '15.0'", s)
    else:
        s="platform :ios, '15.0'\n"+s
    p.write_text(s)
PY

log "13-inch iPad Simulator seçiliyor"
RUNTIME=$(xcrun simctl list runtimes -j | python3 -c 'import json,sys; d=json.load(sys.stdin); a=[x for x in d["runtimes"] if x.get("isAvailable") and "iOS" in x.get("name","")]; print(a[-1]["identifier"] if a else "")')
DTYPE=$(xcrun simctl list devicetypes -j | python3 -c 'import json,sys; d=json.load(sys.stdin); a=[x for x in d["devicetypes"] if "iPad Pro 13-inch" in x["name"]]; b=[x for x in d["devicetypes"] if "iPad Air 13-inch" in x["name"]]; c=[x for x in d["devicetypes"] if "iPad" in x["name"]]; print((a[0] if a else b[0] if b else c[-1])["identifier"] if (a or b or c) else "")')
[[ -n "$RUNTIME" ]] || fail "Kullanılabilir iOS Simulator runtime bulunamadı"
[[ -n "$DTYPE" ]] || fail "Kullanılabilir iPad Simulator device type bulunamadı"

UDID=$(xcrun simctl create "MleySoft AppStore iPad" "$DTYPE" "$RUNTIME")
xcrun simctl boot "$UDID"
xcrun simctl bootstatus "$UDID" -b

# App Store görselinde temiz ve gerçek iOS status bar görünümü.
xcrun simctl status_bar "$UDID" override --time "9:41" --batteryState charged --batteryLevel 100 --wifiBars 3 >/dev/null 2>&1 || true

log "Simulator uygulaması derleniyor - flutter drive KULLANILMIYOR"
# flutter drive / VM Service beklemesi tamamen kaldırıldı. Sadece Simulator .app üretiyoruz.
flutter build ios --simulator --debug --no-pub

APP_PATH="build/ios/iphonesimulator/Runner.app"
[[ -d "$APP_PATH" ]] || fail "Simulator Runner.app bulunamadı: $APP_PATH"

BUNDLE_ID=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$APP_PATH/Info.plist" 2>/dev/null || true)
[[ -n "$BUNDLE_ID" ]] || fail "Simulator uygulamasının bundle id değeri okunamadı"

echo "Simulator bundle: $BUNDLE_ID"
log "Uygulama iPad'e kuruluyor ve açılıyor"
xcrun simctl install "$UDID" "$APP_PATH"
xcrun simctl launch "$UDID" "$BUNDLE_ID"

# Boot ekranı / secure storage başlangıcı tamamlansın ve Login ekranı otursun.
sleep 12

log "Gerçek iOS ekran görüntüsü alınıyor"
SHOT="build/ipad_screenshots/01-login-ipad.png"
xcrun simctl io "$UDID" screenshot --type=png "$SHOT"
[[ -s "$SHOT" ]] || fail "iPad PNG üretilemedi"

# Dosyanın gerçek PNG olduğunu ve boyutunu logla.
file "$SHOT" || true
sips -g pixelWidth -g pixelHeight "$SHOT" || true

# Codemagic resmi custom artifact dizinine de kopyala.
if [[ -n "${CM_EXPORT_DIR:-}" ]]; then
  mkdir -p "$CM_EXPORT_DIR/MleySoft_iPad_Screenshots"
  cp "$SHOT" "$CM_EXPORT_DIR/MleySoft_iPad_Screenshots/"
fi

# Asıl App Store projesini ana Build aşamasından önce geri getir.
restore_project
trap - EXIT

log "IPAD SCREENSHOT V187 HAZIR"
ls -lh build/ipad_screenshots/*.png
