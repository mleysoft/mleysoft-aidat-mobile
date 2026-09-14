#!/bin/bash
set -euo pipefail

ROOT="${CM_BUILD_DIR:-$(pwd)}"
if [ -d "$ROOT/mobile_app/ios" ]; then
  cd "$ROOT/mobile_app"
else
  cd "$ROOT"
fi

echo "========================================"
echo " MLEYSOFT AIDAT - IK PUSH METHOD"
echo "========================================"

ENT="ios/Runner/Runner.entitlements"
PBX="ios/Runner.xcodeproj/project.pbxproj"
INFO="ios/Runner/Info.plist"

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

# EXACT normal-space display name. No unicode escape, no NBSP.
 /usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName MleySoft Aidat" "$INFO"
 /usr/libexec/PlistBuddy -c "Set :CFBundleName Runner" "$INFO"
 /usr/libexec/PlistBuddy -c "Delete :FirebaseAppDelegateProxyEnabled" "$INFO" 2>/dev/null || true

python3 <<'PY'
from pathlib import Path
import re

p = Path("ios/Runner.xcodeproj/project.pbxproj")
s = p.read_text()
bundle = "PRODUCT_BUNDLE_IDENTIFIER = com.mleysoft.aidat;"

# Same strategy as the working MleySoft IK: bind Runner.entitlements
# immediately after EVERY Runner bundle identifier occurrence.
s = re.sub(r'\s*CODE_SIGN_ENTITLEMENTS = Runner/[^;]+;', '', s)
lines = s.splitlines()
out = []
count = 0
for line in lines:
    out.append(line)
    if bundle in line:
        count += 1
        indent = line[:len(line)-len(line.lstrip())]
        out.append(indent + "CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;")

if count < 3:
    raise SystemExit(f"ERROR: Runner bundle-id occurrence beklenenden az: {count}")

s = "\n".join(out) + ("\n" if s.endswith("\n") else "")
p.write_text(s)
print(f"Runner bundle-id occurrence: {count}")
print("CODE_SIGN_ENTITLEMENTS every Runner config'e eklendi.")
PY

# Redundant xcconfig binding, also copied from the working IK setup.
for X in ios/Flutter/Debug.xcconfig ios/Flutter/Release.xcconfig; do
  grep -v '^CODE_SIGN_ENTITLEMENTS' "$X" > "${X}.tmp" || true
  mv "${X}.tmp" "$X"
  echo 'CODE_SIGN_ENTITLEMENTS=Runner/Runner.entitlements' >> "$X"
done

echo ""
echo "===== RUNNER ENTITLEMENTS ====="
cat "$ENT"

echo ""
echo "===== PBX VERIFY ====="
grep -n "CODE_SIGN_ENTITLEMENTS" "$PBX"

test -f ios/Runner/GoogleService-Info.plist
/usr/libexec/PlistBuddy -c "Print :BUNDLE_ID" ios/Runner/GoogleService-Info.plist | grep -q '^com.mleysoft.aidat$'
/usr/libexec/PlistBuddy -c "Print :CFBundleDisplayName" "$INFO" | grep -q '^MleySoft Aidat$'
/usr/libexec/PlistBuddy -c "Print :CFBundleName" "$INFO" | grep -q '^Runner$'
/usr/libexec/PlistBuddy -c "Print :aps-environment" "$ENT" | grep -q '^production$'
grep -q '^CODE_SIGN_ENTITLEMENTS=Runner/Runner.entitlements$' ios/Flutter/Release.xcconfig
grep -q 'CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;' "$PBX"
grep -q "s.dependency 'FirebaseMessaging'" packages/mleysoft_native_bridge/ios/mleysoft_native_bridge.podspec
grep -q 'getNativePushTokens' packages/mleysoft_native_bridge/ios/Classes/MleySoftNativeBridgePlugin.swift
grep -q 'Messaging.messaging().apnsToken = deviceToken' ios/Runner/AppDelegate.swift

echo ""
echo "SUCCESS: IK PUSH METHOD SOURCE CHECKS OK"
echo "Codemagic xcode-project use-profiles sonrasinda provisioning profile production APNs kontrolu Post-build'de de yapilacak."
