#!/usr/bin/env bash
# Build the CLI and Xcode Source Editor Extension in release mode, then install
# the CLI to the Homebrew Cellar (same location `brew install` uses) and the
# app to /Applications.
#
# Both builds run in parallel since they use separate build directories.
set -euo pipefail

cd "$(dirname "$0")/.."

PROJECT=Xcode/Swiftiomatic.xcodeproj
cellar="$(brew --cellar)/sm/dev"
bin_path="$(swift build -c release --show-bin-path)"

mkdir -p "$cellar/bin"

# --- Build CLI and App in parallel ---

echo "Building CLI and app (release, parallel)..."

swift build -c release --product sm 2>&1 | sed 's/^/  [cli] /' &
cli_pid=$!

xcodebuild -project "$PROJECT" \
    -scheme Swiftiomatic \
    -configuration Release \
    -derivedDataPath .build/xcode \
    -quiet \
    ONLY_ACTIVE_ARCH=YES 2>&1 | sed 's/^/  [app] /' &
app_pid=$!

cli_ok=0; wait "$cli_pid" || cli_ok=$?
app_ok=0; wait "$app_pid" || app_ok=$?

if [[ $cli_ok -ne 0 ]]; then
    echo "ERROR: CLI build failed (exit $cli_ok)"
    exit 1
fi
if [[ $app_ok -ne 0 ]]; then
    echo "ERROR: App build failed (exit $app_ok)"
    exit 1
fi

# --- Install CLI ---

src="$bin_path/sm"
if [[ ! -f "$src" ]]; then
    echo "ERROR: sm binary not found at $src"
    exit 1
fi

strip -x -o "$cellar/bin/sm" "$src"
brew link --overwrite sm 2>/dev/null
echo "  sm → $(brew --prefix)/bin/sm"

# --- Install App ---

app="$(find .build/xcode/Build/Products/Release -name 'Swiftiomatic.app' -maxdepth 1 | head -1)"
if [[ -z "$app" ]]; then
    echo "ERROR: Swiftiomatic.app not found in build products"
    exit 1
fi

dest="/Applications/Swiftiomatic.app"
rm -rf "$dest"
cp -R "$app" "$dest"
echo "  Swiftiomatic.app → $dest"

# --- Sync config to extension ---

config="$(git rev-parse --show-toplevel 2>/dev/null)/.swiftiomatic.yaml"
if [[ -f "$config" ]]; then
    defaults write app.toba.swiftiomatic configYAML "$(cat "$config")"
    echo "  .swiftiomatic.yaml → extension defaults"
fi

echo "Done."
