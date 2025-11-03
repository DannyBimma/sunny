#!/usr/bin/env bash
set -euo pipefail

# Build the sunny.app binary from sunny.swift with CoreLocation
cd "$(dirname "$0")"

APP="sunny.app"
BIN="$APP/Contents/MacOS/sunny"

if ! command -v xcrun >/dev/null 2>&1; then
  echo "xcrun not found. Please install Xcode Command Line Tools: xcode-select --install" >&2
  exit 1
fi

mkdir -p "$APP/Contents/MacOS"

echo "Compiling Swift → $BIN"
xcrun --sdk macosx swiftc -O -framework CoreLocation -framework Foundation -o "$BIN" sunny.swift

echo "Ad-hoc signing app bundle (suppresses trust warnings)"
codesign -s - --force --timestamp=none "$APP" 2>/dev/null || true

echo "Done. Launch with: open ./$APP"
