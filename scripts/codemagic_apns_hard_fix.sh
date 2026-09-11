#!/bin/bash
set -euo pipefail

# Supports Codemagic project root at mobile_app OR repository root.
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

if [ ! -f "$PBX" ]; then
    echo "ERROR: $PBX bulunamadi"
    exit 1
fi

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
/usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName MleySoft Aidat" "$INFO" || true
/usr/libexec/PlistBuddy -c "Set :CFBundleName MleySoft Aidat" "$INFO" || true

echo "3) Firebase bundle kontrol ediliyor..."
FB_BUNDLE=$(/usr/libexec/PlistBuddy -c "Print :BUNDLE_ID" "$GOOGLE" 2>/dev/null || true)
if [ "$FB_BUNDLE" != "com.mleysoft.aidat" ]; then
    echo "ERROR: GoogleService-Info.plist BUNDLE_ID=$FB_BUNDLE"
    exit 1
fi

echo "4) Runner Release/Profile configuration'larina CODE_SIGN_ENTITLEMENTS ekleniyor..."

python3 <<'PY'
from pathlib import Path
import re

p = Path("ios/Runner.xcodeproj/project.pbxproj")
s = p.read_text()

BUNDLE = "com.mleysoft.aidat"

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

    if f"PRODUCT_BUNDLE_IDENTIFIER = {BUNDLE};" not in settings:
        raise SystemExit(f"ERROR: {name} bundle id {BUNDLE} degil")

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
print("Release/Profile CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements")
print("Bundle ID = com.mleysoft.aidat")
PY

echo ""
echo "===== RUNNER.ENTITLEMENTS ====="
cat "$ENT"

echo ""
echo "===== PBX VERIFY ====="
grep -n "CODE_SIGN_ENTITLEMENTS" "$PBX"

echo ""
echo "===== XCODE RELEASE SETTINGS ====="

cd ios

SETTINGS=$(xcodebuild \
    -workspace Runner.xcworkspace \
    -scheme Runner \
    -configuration Release \
    -sdk iphoneos \
    -showBuildSettings)

echo "$SETTINGS" | grep -E \
"CODE_SIGN_ENTITLEMENTS|PRODUCT_BUNDLE_IDENTIFIER|INFOPLIST_KEY_CFBundleDisplayName|CODE_SIGN_IDENTITY|DEVELOPMENT_TEAM"

echo ""
echo "===== CRITICAL VERIFY ====="

if ! echo "$SETTINGS" | grep -q \
"CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements"; then
    echo "ERROR: Xcode Release CODE_SIGN_ENTITLEMENTS almadi."
    exit 1
fi

if ! echo "$SETTINGS" | grep -q \
"PRODUCT_BUNDLE_IDENTIFIER = com.mleysoft.aidat"; then
    echo "ERROR: Xcode Release bundle id com.mleysoft.aidat degil."
    exit 1
fi

cd ..

echo ""
echo "========================================"
echo "SUCCESS: AIDAT RELEASE ENTITLEMENT BAGLANDI"
echo "========================================"
