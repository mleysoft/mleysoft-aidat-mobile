#!/usr/bin/env bash
set -euo pipefail

ROOT="${CM_BUILD_DIR:-$(pwd)}"
cd "$ROOT"
if [[ -d mobile_app && -f mobile_app/pubspec.yaml ]]; then cd mobile_app; fi

log(){ printf '\n========== %s ==========\n' "$1"; }
fail(){ echo "ERROR: $1" >&2; exit 1; }

log "MLEYSOFT IPAD SCREENSHOTS V189 - MAESTRO APP ID FIX"
rm -rf build/ipad_screenshots build/maestro-output
mkdir -p build/ipad_screenshots build/maestro-output

# The same public demo login used by App Store reviewers must exist on the API.
# Check it BEFORE a costly iOS simulator build, without printing its token.
log "Demo hesabı API ön kontrolü (20 saniye sınır)"
DEMO_PHONE="${IPAD_DEMO_PHONE:-05555555555}"
DEMO_API="${IPAD_DEMO_API:-https://mleysoft.com/system/aidat/api/mobile/resident-otp-request.php}"
DEMO_REPLY=$(curl --silent --show-error --connect-timeout 8 --max-time 20 \
  --header 'Accept: application/json' --header 'Content-Type: application/json' \
  --data "{\"phone\":\"${DEMO_PHONE}\"}" "$DEMO_API") || fail "Demo API erişilemiyor. Simulator derlemesine başlamıyorum."
if ! printf '%s' "$DEMO_REPLY" | python3 -c '
import json,sys
try:
    d=json.load(sys.stdin)
except Exception:
    print("ERROR: Demo API geçerli JSON döndürmedi.", file=sys.stderr); sys.exit(1)
if d.get("ok") is not True or d.get("demo_login") is not True or not d.get("token"):
    print("ERROR: Demo hesap doğrudan girişe hazır değil: " + str(d.get("message", "demo_login/token yok")), file=sys.stderr)
    sys.exit(1)
print("Demo giriş API doğrulandı (token gizli).")
'; then
  fail "Demo giriş çalışmıyor; altı ekranı üretebilmek için önce sunucudaki demo hesabı etkinleştirilmeli."
fi
unset DEMO_REPLY

log "Maestro CLI kontrolü"
export PATH="$PATH:$HOME/.maestro/bin"
export MAESTRO_CLI_NO_ANALYTICS=1
if ! command -v maestro >/dev/null 2>&1; then
  curl --fail --location --silent --show-error --max-time 150 https://get.maestro.mobile.dev | bash
  export PATH="$PATH:$HOME/.maestro/bin"
fi
command -v maestro >/dev/null 2>&1 || fail "Maestro CLI kurulamadı"
maestro --version

flutter pub get

# Preserve the committed App Store project and AidatShare extension untouched.
[[ -d ios && -f ios/Runner.xcodeproj/project.pbxproj ]] || fail "iOS proje dosyası bulunamadı"
IOS_BACKUP_PARENT=$(mktemp -d)
IOS_BACKUP="$IOS_BACKUP_PARENT/ios"
cp -a ios "$IOS_BACKUP"
UDID=""

export_results(){
  [[ -n "${CM_EXPORT_DIR:-}" ]] || return 0
  mkdir -p "$CM_EXPORT_DIR/MleySoft_iPad_Screenshots"
  find build/ipad_screenshots -maxdepth 1 -type f -name '*.png' -exec cp {} "$CM_EXPORT_DIR/MleySoft_iPad_Screenshots/" \; 2>/dev/null || true
  if find "$CM_EXPORT_DIR/MleySoft_iPad_Screenshots" -maxdepth 1 -type f -name '*.png' | grep -q .; then
    (cd "$CM_EXPORT_DIR/MleySoft_iPad_Screenshots" && zip -q -r "$CM_EXPORT_DIR/MleySoft_iPad_Screenshots.zip" .) || true
  fi
  if [[ -d build/maestro-output ]]; then
    (cd build && zip -q -r "$CM_EXPORT_DIR/MleySoft_Maestro_Diagnostics.zip" maestro-output) || true
  fi
}

on_exit(){
  local rc="$1"
  trap - EXIT
  set +e
  if [[ "$rc" -ne 0 && -n "$UDID" ]]; then
    echo "Screenshot akışı başarısız; son ekran tanılama için kaydediliyor."
    xcrun simctl io "$UDID" screenshot build/ipad_screenshots/00-debug-son-ekran.png || true
  fi
  export_results
  if [[ -d "$IOS_BACKUP" ]]; then
    rm -rf ios
    cp -a "$IOS_BACKUP" ios
  fi
  if [[ -n "$UDID" ]]; then
    xcrun simctl shutdown "$UDID" >/dev/null 2>&1 || true
    xcrun simctl delete "$UDID" >/dev/null 2>&1 || true
  fi
  rm -rf "$IOS_BACKUP_PARENT" >/dev/null 2>&1 || true
  exit "$rc"
}
trap 'on_exit "$?"' EXIT

log "Geçici temiz iOS Simulator projesi hazırlanıyor"
rm -rf ios
flutter create --platforms=ios . >/tmp/mleysoft_flutter_create.log 2>&1 || {
  cat /tmp/mleysoft_flutter_create.log
  fail "Geçici iOS projesi oluşturulamadı"
}
python3 - <<'PY2'
from pathlib import Path
import re
p=Path('ios/Podfile')
if p.exists():
    s=p.read_text()
    if 'platform :ios' in s:
        s=re.sub(r"platform :ios,\s*'[^']+'", "platform :ios, '15.0'", s)
    else:
        s="platform :ios, '15.0'\n"+s
    p.write_text(s)
PY2

log "13-inch iPad Simulator başlatılıyor"
xcrun simctl shutdown all >/dev/null 2>&1 || true
RUNTIME=$(xcrun simctl list runtimes -j | python3 -c 'import json,sys; d=json.load(sys.stdin); a=[x for x in d["runtimes"] if x.get("isAvailable") and "iOS" in x.get("name","")]; print(a[-1]["identifier"] if a else "")')
DTYPE=$(xcrun simctl list devicetypes -j | python3 -c 'import json,sys; d=json.load(sys.stdin); a=[x for x in d["devicetypes"] if "iPad Pro 13-inch" in x["name"]]; b=[x for x in d["devicetypes"] if "iPad Air 13-inch" in x["name"]]; print((a[0] if a else b[0] if b else {}) .get("identifier", ""))')
[[ -n "$RUNTIME" && -n "$DTYPE" ]] || fail "13-inch iPad Simulator runtime/device type bulunamadı"
UDID=$(xcrun simctl create "MleySoft AppStore iPad" "$DTYPE" "$RUNTIME")
xcrun simctl boot "$UDID"
xcrun simctl bootstatus "$UDID" -b
xcrun simctl status_bar "$UDID" override --time '9:41' --batteryState charged --batteryLevel 100 --wifiBars 3 >/dev/null 2>&1 || true

log "Simulator uygulaması tek sefer derleniyor"
flutter build ios --simulator --debug --no-pub
APP_PATH="build/ios/iphonesimulator/Runner.app"
[[ -d "$APP_PATH" ]] || fail "Simulator Runner.app bulunamadı"
BUNDLE_ID=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$APP_PATH/Info.plist" 2>/dev/null || true)
[[ -n "$BUNDLE_ID" ]] || fail "Simulator bundle ID okunamadı"
echo "Simulator bundle: $BUNDLE_ID"
xcrun simctl install "$UDID" "$APP_PATH"
xcrun simctl get_app_container "$UDID" "$BUNDLE_ID" app >/dev/null || fail "Uygulama Simulator'a kurulamadı: $BUNDLE_ID"
xcrun simctl launch "$UDID" "$BUNDLE_ID" || fail "Simulator uygulamayı başlatamadı"

log "Maestro 6 gerçek iPad ekranı - APP_ID açıkça aktarılıyor"
export MAESTRO_DRIVER_STARTUP_TIMEOUT=180000
# Maestro does NOT automatically interpolate ordinary exported shell variables.
# Pass -e APP_ID=... explicitly (Maestro CLI contract), not only export APP_ID.
python3 - "$UDID" "$BUNDLE_ID" "$DEMO_PHONE" <<'PY3'
import subprocess,sys
udid,bundle,phone=sys.argv[1:4]
cmd=['maestro','--device',udid,'test',
     '-e',f'APP_ID={bundle}','-e',f'DEMO_PHONE={phone}',
     '--test-output-dir','build/maestro-output',
     '.maestro/ipad_screenshots.yaml']
print('Maestro APP_ID:',bundle,flush=True)
print('RUN: maestro --device <simulator> test -e APP_ID=<bundle> -e DEMO_PHONE=<demo> ...',flush=True)
try:
    result=subprocess.run(cmd,timeout=300)
except subprocess.TimeoutExpired:
    print('ERROR: Maestro 5 dakikalık süreyi aştı; işlem durduruldu.',file=sys.stderr)
    sys.exit(124)
sys.exit(result.returncode)
PY3

log "Maestro ekran görüntüleri toplanıyor"
find build/maestro-output -type f -name '*.png' -print -exec cp {} build/ipad_screenshots/ \;
for name in 01-login-ipad 02-anasayfa-ipad 03-aidatlar-ipad 04-odemeler-ipad 05-duyurular-ipad 06-talepler-ipad; do
  [[ -s "build/ipad_screenshots/${name}.png" ]] || fail "Eksik screenshot: ${name}.png"
done

log "Gerçek PNG boyutları kontrol ediliyor"
for file in build/ipad_screenshots/*.png; do
  file "$file"
  sips -g pixelWidth -g pixelHeight "$file" || true
done

log "IPAD SCREENSHOTS V189 HAZIR - 6 PNG"
ls -lh build/ipad_screenshots/*.png
# EXIT trap restores the original iOS project and exports the screenshot ZIP.
