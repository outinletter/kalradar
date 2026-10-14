#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
NODE_BIN="${KERADAR_NODE_BIN:-node}"
"$NODE_BIN" "$ROOT/Scripts/generate-project.js"
"$NODE_BIN" "$ROOT/Web/scripts/build.mjs"
"$NODE_BIN" "$ROOT/Web/scripts/check.mjs"
"$NODE_BIN" "$ROOT/Web/scripts/validate-artifact.mjs"
xcodebuild -project "$ROOT/KERadar.xcodeproj" -scheme KERadar -configuration Debug -destination 'generic/platform=iOS' -derivedDataPath "${KERADAR_BUILD_DIR:-$ROOT/build-synchronized}" -allowProvisioningUpdates build
