#!/bin/bash
#
# Regenerate the DEV-badged app icons from the sources in store/:
#   store/appstore_icon_1024.png                 → ios/Runner/Assets.xcassets/AppIcon-Dev.appiconset/*.png
#   store/android_adaptive_foreground_*.png      → android/app/src/dev/res/mipmap-*/ic_launcher_foreground.png
#   (badged icon)                                → android/app/src/dev/res/mipmap-*/ic_launcher.png
#
# The badge itself is drawn by script/make_dev_icons.swift (CoreGraphics, macOS only).
# Run after replacing the app icon; the prod sets are copied by hand from the icon pack.

set -euo pipefail
cd "$(dirname "$0")/.."

ICON=store/appstore_icon_1024.png
FG=$(ls store/android_adaptive_foreground_*.png | head -1)
TMP=$(mktemp -d)

swift script/make_dev_icons.swift "$ICON" "$FG" "$TMP"

IOS=ios/Runner/Assets.xcassets/AppIcon-Dev.appiconset
mkdir -p "$IOS"
for px in 20 29 40 58 60 76 80 87 120 152 167 180 1024; do
    sips -z "$px" "$px" "$TMP/icon_dev_1024.png" --out "$IOS/$px.png" > /dev/null
done
cp ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json "$IOS/Contents.json"

for pair in mdpi:48 hdpi:72 xhdpi:96 xxhdpi:144 xxxhdpi:192; do
    d=${pair%%:*}; px=${pair##*:}
    mkdir -p "android/app/src/dev/res/mipmap-$d"
    sips -z "$px" "$px" "$TMP/icon_dev_1024.png" --out "android/app/src/dev/res/mipmap-$d/ic_launcher.png" > /dev/null
done
for pair in mdpi:108 hdpi:162 xhdpi:216 xxhdpi:324 xxxhdpi:432; do
    d=${pair%%:*}; px=${pair##*:}
    sips -z "$px" "$px" "$TMP/foreground_dev_1024.png" --out "android/app/src/dev/res/mipmap-$d/ic_launcher_foreground.png" > /dev/null
done

rm -rf "$TMP"
echo "✅ DEV icons regenerated ($IOS, android/app/src/dev/res)"
