#!/bin/bash
#
# Interactive release build: asks for flavor / platform / artifact and delegates
# to script/build.sh.

cd "$(dirname "$0")/.."

echo "========================================"
echo "        WasDrop Build Script"
echo "========================================"
echo ""

# Select flavor
echo "Select a flavor:"
echo "1. dev   (com.wasdrop.dev, «WasDrop Dev»)"
echo "2. prod  (com.wasdrop, «WasDrop»)"
echo -n "Enter your choice [1-2]: "
read -r flavor_choice

case $flavor_choice in
    1) build_flavor="dev" ;;
    2) build_flavor="prod" ;;
    *) echo "Invalid option. Exiting."; exit 1 ;;
esac

echo "Selected flavor: $build_flavor"
echo ""

# Select platform
echo "Select a platform:"
echo "1. iOS"
echo "2. Android"
echo -n "Enter your choice [1-2]: "
read -r platform_choice

case $platform_choice in
    1) platform="ios" ;;
    2) platform="android" ;;
    *) echo "Invalid option. Exiting."; exit 1 ;;
esac

echo ""

if [ "$platform" = "android" ]; then
    echo "Select Android artifact:"
    echo "1. APK (testing / direct install)"
    echo "2. AAB (Google Play)"
    echo -n "Enter your choice [1-2]: "
    read -r android_build_type

    case $android_build_type in
        1) target="apk" ;;
        2) target="aab" ;;
        *) echo "Invalid option. Exiting."; exit 1 ;;
    esac

    echo ""
    exec "$PWD/script/build.sh" "$build_flavor" "$target"
else
    echo "Upload to App Store Connect (TestFlight) after archiving?"
    echo "1. Yes — build + upload"
    echo "2. No — build only"
    echo -n "Enter your choice [1-2]: "
    read -r upload_choice

    case $upload_choice in
        1) upload="--upload" ;;
        2) upload="" ;;
        *) echo "Invalid option. Exiting."; exit 1 ;;
    esac

    echo ""
    if [ -n "$upload" ]; then
        exec "$PWD/script/build.sh" "$build_flavor" ipa "$upload"
    else
        exec "$PWD/script/build.sh" "$build_flavor" ipa
    fi
fi
