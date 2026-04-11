#!/usr/bin/env bash
# Build the CLI and Xcode Source Editor Extension in release mode, then install
# the CLI to the Homebrew Cellar (same location `brew install` uses) and the
# app to /Applications.
set -euo pipefail

cd "$(dirname "$0")/.."

PROJECT="Xcode/Swiftiomatic.xcodeproj"

# --- CLI (Swift Package) ---

bin="$(realpath "$(brew --prefix swiftiomatic)/bin")"

echo "Building CLI (release)..."
swift build -c release

src="$(swift build -c release --show-bin-path)/swiftiomatic"
if [[ ! -f "$src" ]]; then
    echo "  ERROR: swiftiomatic binary not found at $src"
    exit 1
fi

strip -x -o "$bin/swiftiomatic" "$src"
echo "  swiftiomatic → $bin/swiftiomatic"

# --- App + Source Editor Extension (Xcode project) ---

echo "Building app (release)..."
rm -rf .build/xcode
xcodebuild -project "$PROJECT" \
    -scheme Swiftiomatic \
    -configuration Release \
    -derivedDataPath .build/xcode \
    -quiet

app="$(find .build/xcode/Build/Products/Release -name 'Swiftiomatic.app' -maxdepth 1 | head -1)"
if [[ -z "$app" ]]; then
    echo "  ERROR: Swiftiomatic.app not found in build products"
    exit 1
fi

dest="/Applications/Swiftiomatic.app"
rm -rf "$dest"
cp -R "$app" "$dest"
echo "  Swiftiomatic.app → $dest"

echo "Done."
