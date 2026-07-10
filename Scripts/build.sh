#!/bin/bash
# Rainier build script.
#
# SwiftPM (`swift build`) is the canonical build, but this script compiles the
# same sources directly with swiftc so the project builds even on machines
# where the SwiftPM half of the Command Line Tools is broken. App sources
# guard their `import RainierCore` with `#if canImport(RainierCore)` so they
# compile both as separate SwiftPM modules and as one unified module here.
#
# Usage:
#   Scripts/build.sh            release build -> dist/rainier
#   Scripts/build.sh --debug    debug build
#   Scripts/build.sh --tests    build + run the test executable
set -euo pipefail
cd "$(dirname "$0")/.."

MODE_FLAGS="-O"
[[ "${1:-}" == "--debug" ]] && MODE_FLAGS="-Onone -g"

mkdir -p dist
CORE_SOURCES=($(find Sources/RainierCore -name "*.swift" | sort))

if [[ "${1:-}" == "--tests" ]]; then
  xcrun swiftc $MODE_FLAGS \
    "${CORE_SOURCES[@]}" Sources/RainierTests/*.swift \
    -o dist/rainier-tests
  exec ./dist/rainier-tests
fi

xcrun swiftc $MODE_FLAGS \
  "${CORE_SOURCES[@]}" Sources/Rainier/*.swift \
  -framework AppKit -framework IOKit \
  -o dist/rainier
echo "built dist/rainier"
