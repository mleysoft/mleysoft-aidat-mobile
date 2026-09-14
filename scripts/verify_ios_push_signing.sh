#!/usr/bin/env bash
set -euo pipefail

PROFILE_DIR="$HOME/Library/Developer/Xcode/UserData/Provisioning Profiles"
TMP="/tmp/mleysoft_aidat_profile.plist"
FOUND=0

for P in "$PROFILE_DIR"/*.mobileprovision "$HOME/Library/MobileDevice/Provisioning Profiles"/*.mobileprovision; do
  [ -f "$P" ] || continue
  security cms -D -i "$P" > "$TMP" 2>/dev/null || continue
  APPID=$(/usr/libexec/PlistBuddy -c 'Print :Entitlements:application-identifier' "$TMP" 2>/dev/null || true)

  case "$APPID" in
    *.com.mleysoft.aidat)
      FOUND=1
      APS=$(/usr/libexec/PlistBuddy -c 'Print :Entitlements:aps-environment' "$TMP" 2>/dev/null || true)
      echo "MleySoft Aidat profile: $P"
      echo "application-identifier=$APPID"
      echo "aps-environment=${APS:-MISSING}"
      [ "$APS" = "production" ] || {
        echo "ERROR: Apple provisioning profile production aps-environment icermiyor."
        echo "Apple Developer Push Notifications capability acikken App Store profile'i yeniden olusturun/refetch edin."
        exit 41
      }
      ;;
  esac
done

[ "$FOUND" = 1 ] || {
  echo "ERROR: com.mleysoft.aidat App Store provisioning profile bulunamadi."
  exit 42
}

echo "PROFILE VERIFY OK: provisioning profile contains aps-environment=production."
