#!/bin/sh
# Builds DayCoach.app into build/. SwiftPM produces a bare executable; the app needs a
# bundle with an identifier for notifications to work (ADR 0001), so we assemble one
# and sign it ad hoc (enough to run it on this Mac).
#
#   scripts/build-app.sh            release build
#   scripts/build-app.sh debug      debug build
set -eu
cd "$(dirname "$0")/.."

configuration="${1:-release}"
app="build/DayCoach.app"

swift build -c "$configuration" --product DayCoach
binary="$(swift build -c "$configuration" --show-bin-path)/DayCoach"

rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp "$binary" "$app/Contents/MacOS/DayCoach"

cat > "$app/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>io.github.camilgun.daycoach</string>
    <key>CFBundleName</key>
    <string>Day Coach</string>
    <key>CFBundleDisplayName</key>
    <string>Day Coach</string>
    <key>CFBundleExecutable</key>
    <string>DayCoach</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>0.1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.productivity</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

codesign --force --sign - "$app"
echo "Built $app"
