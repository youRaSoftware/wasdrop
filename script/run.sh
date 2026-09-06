#!/bin/bash
#
# Run the app for a flavor (native --flavor + dart-define in one go).
#
#   script/run.sh dev            # debug on the current device
#   script/run.sh prod --release
#   script/run.sh dev -d <deviceId>

set -euo pipefail
cd "$(dirname "$0")/.."

FLAVOR="${1:-}"
case "$FLAVOR" in
    dev|prod) shift ;;
    *) echo "Usage: script/run.sh <dev|prod> [flutter run args...]"; exit 1 ;;
esac

exec flutter run --flavor "$FLAVOR" --dart-define="environment=$FLAVOR" "$@"
