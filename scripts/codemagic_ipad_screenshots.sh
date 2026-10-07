#!/usr/bin/env bash
set -euo pipefail

ROOT="${CM_BUILD_DIR:-$(pwd)}"
cd "$ROOT"
if [[ -d mobile_app && -f mobile_app/pubspec.yaml ]]; then cd mobile_app; fi

log(){ printf '\n========== %s ==========\n' "$1"; }
fail(){ echo "ERROR: $1" >&2; exit 1; }

log "MLEYSOFT IPAD SCREENSHOTS V188 - MAESTRO IOS UI"
rm -rf build/ipad_screenshots build/maestro-output
mkdir -p build/ipad_screenshots build/maestro-output
flutter pub get

# Asıl App Store iOS projesi/AidatShare hiç değiştirilmeden geri konacak.
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

log "13-inch iPad Simulator seçiliyor"
xcrun simctl shutdown all >/dev/null 2>&1 || true
RUNTIME=$(xcrun simctl list runtimes -j | python3 -c 'import json,sys; d=json.load(sys.stdin); a=[x for x in d["runtimes"] if x.get("isAvailable") and "iOS" in x.get("name","")]; print(a[-1]["identifier"] if a else "")')
DTYPE=$(xcrun simctl list devicetypes -j | python3 -c 'import json,sys; d=json.load(sys.stdin); a=[x for x in d["devicetypes"] if "iPad Pro 13-inch" in x["name"]]; b=[x for x in d["devicetypes"] if "iPad Air 13-inch" in x["name"]]; c=[x for x in d["devicetypes"] if "iPad" in x["name"]]; print((a[0] if a else b[0] if b else c[-1])["identifier"] if (a or b or c) else "")')
[[ -n "$RUNTIME" ]] || fail "Kullanılabilir iOS Simulator runtime bulunamadı"
[[ -n "$DTYPE" ]] || fail "Kullanılabilir 13-inch iPad Simulator bulunamadı"
UDID=$(xcrun simctl create "MleySoft AppStore iPad" "$DTYPE" "$RUNTIME")
xcrun simctl boot "$UDID"
xcrun simctl bootstatus "$UDID" -b
xcrun simctl status_bar "$UDID" override --time "9:41" --batteryState charged --batteryLevel 100 --wifiBars 3 >/dev/null 2>&1 || true

log "Simulator .app tek sefer derleniyor"
flutter build ios --simulator --debug --no-pub
APP_PATH="build/ios/iphonesimulator/Runner.app"
[[ -d "$APP_PATH" ]] || fail "Simulator Runner.app bulunamadı: $APP_PATH"
BUNDLE_ID=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$APP_PATH/Info.plist" 2>/dev/null || true)
[[ -n "$BUNDLE_ID" ]] || fail "Simulator bundle id okunamadı"
echo "Simulator bundle: $BUNDLE_ID"
xcrun simctl install "$UDID" "$APP_PATH"

log "Maestro CLI kuruluyor / doğrulanıyor"
export PATH="$PATH:$HOME/.maestro/bin"
if ! command -v maestro >/dev/null 2>&1; then
  curl -Ls "https://get.maestro.mobile.dev" | bash
  export PATH="$PATH:$HOME/.maestro/bin"
fi
command -v maestro >/dev/null 2>&1 || fail "Maestro CLI kurulamadı"
maestro --version || true

log "Gerçek kullanıcı akışı: login + 5 uygulama ekranı"
export APP_ID="$BUNDLE_ID"
export MAESTRO_DRIVER_STARTUP_TIMEOUT=180000
# Dışarıdan iOS erişilebilirlik katmanıyla dokunur/yazar; Flutter VM Service kullanmaz.
# Python timeout sayesinde CI hiçbir koşulda saatlerce bu adımda kalmaz.
python3 - "$UDID" <<'PY3'
import os, subprocess, sys
udid=sys.argv[1]
cmd=['maestro','--device',udid,'test','.maestro/ipad_screenshots.yaml','--test-output-dir','build/maestro-output']
print('RUN:', ' '.join(cmd), flush=True)
try:
    r=subprocess.run(cmd, env=os.environ.copy(), timeout=360)
except subprocess.TimeoutExpired:
    print('ERROR: Maestro 6 dakikalık güvenlik süresini aştı; işlem zorla durduruldu.', file=sys.stderr)
    sys.exit(124)
sys.exit(r.returncode)
PY3

# Maestro ekran görüntülerini test artifact yapısından tek klasörde topla.
find build/maestro-output -type f -name '*.png' -print -exec cp {} build/ipad_screenshots/ \; || true

COUNT=$(find build/ipad_screenshots -maxdepth 1 -type f -name '*.png' | wc -l | tr -d ' ')
[[ "$COUNT" -ge 6 ]] || {
  echo "Üretilen PNG sayısı: $COUNT"
  find build/ipad_screenshots -maxdepth 1 -type f -print || true
  fail "6 iPad screenshot bekleniyordu"
}

log "PNG boyutları doğrulanıyor"
for f in build/ipad_screenshots/*.png; do
  echo "--- $f"
  file "$f" || true
  sips -g pixelWidth -g pixelHeight "$f" || true
done

log "Codemagic artifact dizinine kopyalanıyor"
if [[ -n "${CM_EXPORT_DIR:-}" ]]; then
  rm -rf "$CM_EXPORT_DIR/MleySoft_iPad_Screenshots"
  mkdir -p "$CM_EXPORT_DIR/MleySoft_iPad_Screenshots"
  cp build/ipad_screenshots/*.png "$CM_EXPORT_DIR/MleySoft_iPad_Screenshots/"
  (cd build/ipad_screenshots && zip -q "$CM_EXPORT_DIR/MleySoft_iPad_Screenshots.zip" ./*.png)
fi

restore_project
trap - EXIT
log "IPAD SCREENSHOTS V188 HAZIR - 6 PNG"
ls -lh build/ipad_screenshots/*.png
