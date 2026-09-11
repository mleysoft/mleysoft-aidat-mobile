#!/bin/bash
set -euo pipefail

ROOT="${CM_BUILD_DIR:-$(pwd)}"
if [ -d "$ROOT/mobile_app/ios" ]; then
    cd "$ROOT/mobile_app"
else
    cd "$ROOT"
fi

echo "========================================"
echo " MLEYSOFT AIDAT APNS ENTITLEMENT HARD FIX"
echo "========================================"

ENT="ios/Runner/Runner.entitlements"
PBX="ios/Runner.xcodeproj/project.pbxproj"
INFO="ios/Runner/Info.plist"
GOOGLE="ios/Runner/GoogleService-Info.plist"

for FILE in "$PBX" "$INFO" "$GOOGLE"; do
    if [ ! -f "$FILE" ]; then
        echo "ERROR: $FILE bulunamadi"
        exit 1
    fi
done

echo "1) Runner.entitlements PRODUCTION olusturuluyor..."
cat > "$ENT" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>aps-environment</key>
    <string>production</string>
</dict>
</plist>
EOF

echo "2) iOS gorunen uygulama adi zorlanıyor..."
/usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName MleySoft Aidat" "$INFO" 2>/dev/null || \
/usr/libexec/PlistBuddy -c "Add :CFBundleDisplayName string MleySoft Aidat" "$INFO"
/usr/libexec/PlistBuddy -c "Set :CFBundleName MleySoft Aidat" "$INFO" 2>/dev/null || \
/usr/libexec/PlistBuddy -c "Add :CFBundleName string MleySoft Aidat" "$INFO"

echo "3) Firebase bundle kontrol ediliyor..."
FB_BUNDLE=$(/usr/libexec/PlistBuddy -c "Print :BUNDLE_ID" "$GOOGLE" 2>/dev/null || true)
if [ "$FB_BUNDLE" != "com.mleysoft.aidat" ]; then
    echo "ERROR: GoogleService-Info.plist BUNDLE_ID=$FB_BUNDLE"
    echo "Beklenen: com.mleysoft.aidat"
    exit 1
fi

echo "4) Runner Release/Profile entitlement ve app-name baglantisi yaziliyor..."
python3 <<'PY'
from pathlib import Path
import re

p = Path("ios/Runner.xcodeproj/project.pbxproj")
s = p.read_text()
bundle = "com.mleysoft.aidat"
configs = [
    ("249021D3217E4FDB00AE95B9", "Profile"),
    ("97C147071CF9000F007C117D", "Release"),
]

for config_id, name in configs:
    pat = rf"({config_id} /\* {name} \*/ = \{{isa = XCBuildConfiguration;.*?buildSettings = \{{)(.*?)(\}}; name = {name}; \}};)"
    m = re.search(pat, s)
    if not m:
        raise SystemExit(f"ERROR: {name} Runner configuration bulunamadi")
    settings = m.group(2)

    if f"PRODUCT_BUNDLE_IDENTIFIER = {bundle};" not in settings:
        raise SystemExit(f"ERROR: {name} PRODUCT_BUNDLE_IDENTIFIER {bundle} degil")

    settings = re.sub(r"\s*CODE_SIGN_ENTITLEMENTS = .*?;", "", settings)
    settings = re.sub(r"\s*INFOPLIST_KEY_CFBundleDisplayName = .*?;", "", settings)
    settings = re.sub(r"\s*INFOPLIST_KEY_CFBundleName = .*?;", "", settings)

    prefix = (
        " CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;"
        ' INFOPLIST_KEY_CFBundleDisplayName = "MleySoft Aidat";'
        ' INFOPLIST_KEY_CFBundleName = "MleySoft Aidat";'
    )
    s = s[:m.start(2)] + prefix + settings + s[m.end(2):]

p.write_text(s)

check = p.read_text()
for config_id, name in configs:
    pat = rf"{config_id} /\* {name} \*/ = \{{isa = XCBuildConfiguration;.*?buildSettings = \{{(.*?)\}}; name = {name}; \}};"
    m = re.search(pat, check)
    if not m:
        raise SystemExit(f"ERROR: {name} verification configuration bulunamadi")
    settings = m.group(1)
    required = [
        "CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;",
        "PRODUCT_BUNDLE_IDENTIFIER = com.mleysoft.aidat;",
        'INFOPLIST_KEY_CFBundleDisplayName = "MleySoft Aidat";',
        'INFOPLIST_KEY_CFBundleName = "MleySoft Aidat";',
    ]
    for value in required:
        if value not in settings:
            raise SystemExit(f"ERROR: {name} icinde eksik ayar: {value}")

print("Release/Profile PBX ayarlari dogrulandi.")
PY

echo ""
echo "===== RUNNER.ENTITLEMENTS ====="
cat "$ENT"

echo ""
echo "===== PBX VERIFY ====="
grep -n "CODE_SIGN_ENTITLEMENTS" "$PBX" || true

echo ""
echo "===== PRE-BUILD CRITICAL VERIFY ====="
APS=$(/usr/libexec/PlistBuddy -c "Print :aps-environment" "$ENT" 2>/dev/null || true)
DISPLAY=$(/usr/libexec/PlistBuddy -c "Print :CFBundleDisplayName" "$INFO" 2>/dev/null || true)

if [ "$APS" != "production" ]; then
    echo "ERROR: Runner.entitlements production degil: $APS"
    exit 1
fi
if [ "$DISPLAY" != "MleySoft Aidat" ]; then
    echo "ERROR: CFBundleDisplayName MleySoft Aidat degil: $DISPLAY"
    exit 1
fi

echo ""
echo "========================================"
echo "SUCCESS: AIDAT PRE-BUILD HARD FIX TAMAM"
echo " - entitlement = production"
echo " - bundle = com.mleysoft.aidat"
echo " - app name = MleySoft Aidat"
echo "========================================"
