#!/bin/bash
#
# Run tests in every package that has a test/ folder and merge coverage into
# coverage/lcov.info (+ HTML report if `genhtml` from lcov is installed).

set -uo pipefail
cd "$(dirname "$0")/.."

PACKAGES=(. core core_ui data domain features navigation)
ROOT="$PWD"
FAILED=0

rm -rf "$ROOT/coverage"
mkdir -p "$ROOT/coverage"

for pkg in "${PACKAGES[@]}"; do
    if [ ! -d "$pkg/test" ]; then
        continue
    fi

    echo ""
    echo "🧪 flutter test → $pkg"
    (
        cd "$pkg" || exit 1
        rm -rf coverage
        flutter test --coverage
    ) || FAILED=1

    if [ -f "$pkg/coverage/lcov.info" ]; then
        prefix="${pkg#./}"
        if [ "$prefix" = "." ]; then
            cat "$pkg/coverage/lcov.info" >> "$ROOT/coverage/lcov.info"
        else
            # Rewrite SF:lib/... → SF:<package>/lib/... so paths resolve from the repo root.
            sed -e "s#^SF:lib/#SF:$prefix/lib/#" "$pkg/coverage/lcov.info" >> "$ROOT/coverage/lcov.info"
        fi
    fi
done

echo ""
if [ "$FAILED" -ne 0 ]; then
    echo "❌ Some tests failed"
    exit 1
fi

echo "✅ All tests passed"

if [ -s "$ROOT/coverage/lcov.info" ] && command -v genhtml > /dev/null; then
    genhtml "$ROOT/coverage/lcov.info" -o "$ROOT/coverage/html" > /dev/null
    echo "📊 Coverage report: coverage/html/index.html"
    open "$ROOT/coverage/html/index.html" 2>/dev/null || true
fi
