#!/usr/bin/env bash
# Build sm in release mode and install to the Homebrew Cellar,
# same location `brew install` uses. Compatible with `brew upgrade`.
set -euo pipefail

cd "$(dirname "$0")/.."

# Derive version from the latest git tag (e.g. v0.27.1 → 0.27.1).
version="$(git describe --tags --abbrev=0 2>/dev/null | sed 's/^v//')"
if [[ -z "$version" ]]; then
    echo "  ERROR: no git tag found"
    exit 1
fi

# Embed version in source before building.
sed -i '' "s/let smVersion = \".*\"/let smVersion = \"$version\"/" Sources/Swiftiomatic/Version.swift

cellar="$(brew --cellar sm)/$version"
mkdir -p "$cellar/bin"

# Activate committed git hooks.
git config core.hooksPath scripts

echo "Regenerating schema..."
swift run Generator
echo "Building release..."
swift build -c release --product sm

src="$(swift build -c release --product sm --show-bin-path)/sm"
if [[ ! -f "$src" ]]; then
    echo "  ERROR: sm not found at $src"
    exit 1
fi

strip -x -o "$cellar/bin/sm" "$src"
echo "  sm → $cellar/bin/sm"

# Point Homebrew's opt symlink at the new version.
brew unlink sm 2>/dev/null || true
brew link --overwrite sm 2>/dev/null || ln -sf "$cellar/bin/sm" "$(brew --prefix)/bin/sm"
echo "  Homebrew linked: $(readlink "$(brew --prefix)/bin/sm")"

# Refresh Xcode toolchain symlink so Editor → Format with swift-format works.
xc_bin="/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swift-format"
if [[ -e "$xc_bin" && ! -L "$xc_bin" ]] || [[ "$(readlink "$xc_bin" 2>/dev/null)" != "$(brew --prefix)/bin/sm" ]]; then
    sudo ln -sf "$(brew --prefix)/bin/sm" "$xc_bin"
    echo "  Xcode symlink refreshed: $xc_bin → $(brew --prefix)/bin/sm"
else
    echo "  Xcode symlink OK"
fi

echo "Done. Installed sm $version."
