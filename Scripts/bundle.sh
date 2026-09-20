#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")/.."

VERSION="$(tr -d '[:space:]' < VERSION)"
APP="build.noindex/Codex Hair Bar.app"
EXECUTABLE="CodexHairBar"
BUNDLE_ID="io.github.oscs1024.CodexHairBar"

echo "Building Codex Hair Bar $VERSION (universal)…"

swift build -c release --arch arm64 --arch x86_64
BUILT="$(swift build -c release --arch arm64 --arch x86_64 --show-bin-path)"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
touch "build.noindex/.metadata_never_index"

cp "$BUILT/$EXECUTABLE" "$APP/Contents/MacOS/$EXECUTABLE"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>Codex Hair Bar</string>
    <key>CFBundleDisplayName</key><string>Codex Hair Bar</string>
    <key>CFBundleExecutable</key><string>$EXECUTABLE</string>
    <key>CFBundleIdentifier</key><string>$BUNDLE_ID</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>$VERSION</string>
    <key>CFBundleVersion</key><string>$VERSION</string>
    <key>LSMinimumSystemVersion</key><string>14.0</string>
    <key>LSUIElement</key><true/>
    <key>NSHighResolutionCapable</key><true/>
    <key>NSHumanReadableCopyright</key><string>Codex Hair Bar contributors</string>
</dict>
</plist>
PLIST

codesign --force --deep --sign - "$APP" 2>/dev/null || echo "  (ad-hoc signing skipped)"

echo "→ $APP"

if [ "${1:-}" = "--zip" ]; then
    ZIP="build.noindex/Codex-Hair-Bar-$VERSION.zip"
    rm -f "$ZIP"
    ditto -c -k --keepParent "$APP" "$ZIP"
    echo "→ $ZIP"
fi

[ "${1:-}" = "--open" ] && open -R "$APP"
