#!/usr/bin/env bash
# Build sm in release mode and install to the Homebrew Cellar,
# same location `brew install` uses. Compatible with `brew upgrade`.
set -euo pipefail

bin="$(realpath "$(brew --prefix sm)/bin")"

cd "$(dirname "$0")/.."

echo "Building release..."
swift build -c release --product sm

src="$(swift build -c release --product sm --show-bin-path)/sm"
if [[ ! -f "$src" ]]; then
    echo "  ERROR: sm not found at $src"
    exit 1
fi

strip -x -o "$bin/sm" "$src"
echo "  sm → $bin/sm"

echo "Done."
