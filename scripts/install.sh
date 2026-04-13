#!/usr/bin/env bash
# Build the CLI and Xcode Source Editor Extension in release mode, then install
# the CLI to the Homebrew Cellar (same location `brew install` uses) and the
# app to /Applications.
set -euo pipefail

cd "$(dirname "$0")/.."

PROJECT="Xcode/Swiftiomatic.xcodeproj"

# --- CLI (Swift Package) ---

cellar="$(brew --cellar)/sm/dev"
mkdir -p "$cellar/bin"

echo "Building CLI (release)..."
swift build -c release

src="$(swift build -c release --show-bin-path)/sm"
if [[ ! -f "$src" ]]; then
    echo "  ERROR: sm binary not found at $src"
    exit 1
fi

strip -x -o "$cellar/bin/sm" "$src"
brew link --overwrite sm
echo "  sm → $(brew --prefix)/bin/sm"

# --- App + Source Editor Extension (Xcode project) ---

echo "Building app (release)..."
xcodebuild -project "$PROJECT" \
    -scheme Swiftiomatic \
    -configuration Release \
    -derivedDataPath .build/xcode \
    ONLY_ACTIVE_ARCH=YES

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
