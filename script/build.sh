#!/bin/bash
#
# Non-interactive release build for one flavor + target.
#
#   script/build.sh <dev|prod> <apk|aab|ipa> [--upload]
#
#   apk  → build/app/outputs/flutter-apk/app-<flavor>-release.apk
#   aab  → build/app/outputs/bundle/<flavor>Release/app-<flavor>-release.aab
#   ipa  → build/ios/ipa/*.ipa (+ Runner.xcarchive); with --upload the archive is
#          exported straight to App Store Connect (TestFlight)
#
# Interactive wrapper: script/build_app_builds.sh

set -euo pipefail
cd "$(dirname "$0")/.."

FLAVOR="${1:-}"
TARGET="${2:-}"
UPLOAD="${3:-}"

usage() {
    echo "Usage: script/build.sh <dev|prod> <apk|aab|ipa> [--upload]"
    exit 1
}

case "$FLAVOR" in
    dev|prod) ;;
    *) echo "❌ Unknown flavor: '$FLAVOR'"; usage ;;
esac

case "$TARGET" in
    apk|aab|ipa) ;;
    *) echo "❌ Unknown target: '$TARGET'"; usage ;;
esac

if [ -n "$UPLOAD" ] && [ "$UPLOAD" != "--upload" ]; then
    echo "❌ Unknown option: '$UPLOAD'"; usage
fi

VERSION="$(grep -E '^version:' pubspec.yaml | awk '{print $2}')"
FLUTTER_ARGS=(--release --flavor "$FLAVOR" --dart-define="environment=$FLAVOR")

echo "========================================"
echo "  WasDrop build · $FLAVOR · $TARGET · v$VERSION"
echo "========================================"
echo ""

case "$TARGET" in
    apk)
        flutter build apk "${FLUTTER_ARGS[@]}"
        echo ""
        echo "✅ APK: build/app/outputs/flutter-apk/app-$FLAVOR-release.apk"
        ;;

    aab)
        flutter build appbundle "${FLUTTER_ARGS[@]}"
        echo ""
        echo "✅ AAB: build/app/outputs/bundle/${FLAVOR}Release/app-$FLAVOR-release.aab"
        echo "📤 Upload: https://play.google.com/console"
        ;;

    ipa)
        flutter build ipa "${FLUTTER_ARGS[@]}"
        echo ""
        echo "✅ Archive: build/ios/archive/Runner.xcarchive"
        ls build/ios/ipa/*.ipa 2>/dev/null | sed 's/^/✅ IPA: /' || true

        if [ "$UPLOAD" = "--upload" ]; then
            # exportOptions.plist is ignored by git (contains nothing secret, but is machine-specific).
            if [ ! -f ios/exportOptions.plist ]; then
                echo "Creating ios/exportOptions.plist (app-store-connect, upload)..."
                cat > ios/exportOptions.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store-connect</string>
    <key>destination</key>
    <string>upload</string>
</dict>
</plist>
EOF
            fi

            echo ""
            echo "Uploading to App Store Connect..."
            xcodebuild -exportArchive \
                -archivePath "$PWD/build/ios/archive/Runner.xcarchive" \
                -exportOptionsPlist ios/exportOptions.plist \
                -exportPath "$PWD/build/ios/ipa/" \
                -allowProvisioningUpdates

            echo ""
            echo "✅ Uploaded — check TestFlight in App Store Connect"
        else
            echo "ℹ️  To upload: script/build.sh $FLAVOR ipa --upload  (or drag the .ipa into Transporter)"
        fi
        ;;
esac

echo ""
echo "========================================"
echo "              Done!"
echo "========================================"
