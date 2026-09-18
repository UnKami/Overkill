#!/usr/bin/env bash
# Builds the Windows installer from the current repo state and deploys the
# landing page + installer to Firebase Hosting. Version is read from the
# repo-root VERSION file — bump that file before running this.
set -euo pipefail
cd "$(dirname "$0")/../.."

GODOT="/c/Users/Yonatan/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe"
ISCC="/c/Users/Yonatan/AppData/Local/Programs/Inno Setup 6/ISCC.exe"
VERSION=$(tr -d '[:space:]' < VERSION)

echo "== Building OVERKILL v$VERSION =="

echo "-- Godot export (Windows Desktop) --"
mkdir -p build/windows
"$GODOT" --headless --path "$(pwd)" --export-release "Windows Desktop" "build/windows/Overkill.exe"

echo "-- Compiling installer (Inno Setup) --"
mkdir -p build/installer
MSYS_NO_PATHCONV=1 "$ISCC" "/DAppVersion=$VERSION" "installer/overkill.iss"

INSTALLER_NAME="OverkillSetup-$VERSION.exe"
echo "-- Staging public/downloads --"
mkdir -p public/downloads
rm -f public/downloads/OverkillSetup-*.exe
cp "build/installer/$INSTALLER_NAME" "public/downloads/$INSTALLER_NAME"

echo "-- Writing version.json --"
cat > public/version.json <<EOF
{
  "version": "$VERSION",
  "file": "$INSTALLER_NAME",
  "url": "/downloads/$INSTALLER_NAME",
  "releasedAt": "$(date +%Y-%m-%d)"
}
EOF

echo "-- Deploying to Firebase Hosting --"
firebase deploy --only hosting --project overkill-86f3e

echo "== Done: https://overkill-86f3e.web.app =="
