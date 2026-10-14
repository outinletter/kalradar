#!/bin/sh
# Runs the same pure filtering/decoding/request tests on macOS, without a simulator.
# Usage: Scripts/run-core-tests.sh /absolute/scratch/path
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
SCRATCH=${1:-$(mktemp -d /tmp/keradar-core-tests.XXXXXX)}
mkdir -p "$SCRATCH/Package/Sources/KERadar" "$SCRATCH/Package/Tests/KERadarTests"
cp "$ROOT/KERadar/Flight.swift" "$ROOT/KERadar/FR24Client.swift" "$SCRATCH/Package/Sources/KERadar/"
cp "$ROOT/KERadarTests/FlightTests.swift" "$SCRATCH/Package/Tests/KERadarTests/"
cat > "$SCRATCH/Package/Package.swift" <<'MANIFEST'
// swift-tools-version: 5.9
import PackageDescription
let package = Package(name: "KERadarCoreTests", platforms: [.macOS(.v13)], products: [.library(name: "KERadar", targets: ["KERadar"])], targets: [.target(name: "KERadar"), .testTarget(name: "KERadarTests", dependencies: ["KERadar"])])
MANIFEST
export DEVELOPER_DIR=${DEVELOPER_DIR:-/Applications/Xcode-Internal.app/Contents/Developer}
xcrun swift test --package-path "$SCRATCH/Package" --scratch-path "$SCRATCH/Build"
