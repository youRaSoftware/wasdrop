#!/bin/bash
#
# Regenerate the native launch-screen images (rounded app icon, 120 dp/pt)
# from store/appstore_icon_1024.png:
#   ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage{,@2x,@3x}.png
#   android/app/src/main/res/drawable-*/launch_image.png
# The rounding is drawn by script/make_launch_image.swift (CoreGraphics, macOS only).
# Run after replacing the app icon (together with script/gen_dev_icons.sh).

set -euo pipefail
cd "$(dirname "$0")/.."

ICON=store/appstore_icon_1024.png
TMP=$(mktemp -d)

swift script/make_launch_image.swift "$ICON" "$TMP" 120,180,240,360,480 > /dev/null

IOS=ios/Runner/Assets.xcassets/LaunchImage.imageset
cp "$TMP/launch_120.png" "$IOS/LaunchImage.png"
cp "$TMP/launch_240.png" "$IOS/LaunchImage@2x.png"
cp "$TMP/launch_360.png" "$IOS/LaunchImage@3x.png"

for pair in mdpi:120 hdpi:180 xhdpi:240 xxhdpi:360 xxxhdpi:480; do
    d=${pair%%:*}; px=${pair##*:}
    mkdir -p "android/app/src/main/res/drawable-$d"
    cp "$TMP/launch_$px.png" "android/app/src/main/res/drawable-$d/launch_image.png"
done

rm -rf "$TMP"
echo "✅ Launch images regenerated ($IOS, android/app/src/main/res/drawable-*)"
