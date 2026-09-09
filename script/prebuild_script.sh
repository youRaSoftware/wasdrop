#!/bin/bash
#
# Prebuild: `flutter pub get` in every package, then build_runner in the
# packages that declare it (none today — freezed/hive codegen is not used yet).
#
#   script/prebuild_script.sh          # pub get (+ codegen where declared)
#   script/prebuild_script.sh --clean  # flutter clean first

set -euo pipefail
cd "$(dirname "$0")/.."

PACKAGES=(. core core_ui data domain features navigation)

if [ "${1:-}" = "--clean" ]; then
    for pkg in "${PACKAGES[@]}"; do
        echo "🧹 flutter clean → $pkg"
        (cd "$pkg" && flutter clean > /dev/null)
    done
fi

for pkg in "${PACKAGES[@]}"; do
    echo "📦 flutter pub get → $pkg"
    (cd "$pkg" && flutter pub get)
done

# Ключи переводов (LocaleKeys) из core/resources/translations/*.json.
if grep -q "easy_localization" core/pubspec.yaml; then
    echo "🌐 locale keys → core/lib/localization/locale_keys.g.dart"
    (cd core && dart run easy_localization:generate -f keys -o locale_keys.g.dart -O lib/localization -S resources/translations)
fi

for pkg in "${PACKAGES[@]}"; do
    if grep -q "build_runner" "$pkg/pubspec.yaml"; then
        echo "⚙️  build_runner → $pkg"
        (cd "$pkg" && dart run build_runner build --delete-conflicting-outputs)
    fi
done

echo ""
echo "✅ Prebuild done"
