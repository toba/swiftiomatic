#!/bin/bash
# Remove swift-frontend intermediate files that leak into the project root.
#
# `swift build` occasionally drops `.d`, `.dia`, `.swiftdeps`, and
# `.swiftmodule` files for the build-plugin–generated sources (e.g.
# `Pipelines+Generated-2.swiftmodule`) into the package root. They are
# already in `.gitignore` but still pollute `ls`. This script removes them.
#
# Usage: scripts/clean-stray-artifacts.sh
set -euo pipefail

cd "$(dirname "$0")/.."

shopt -s nullglob
artifacts=(*+Generated-*.d *+Generated-*.dia *+Generated-*.swiftdeps *+Generated-*.swiftmodule)

if (( ${#artifacts[@]} == 0 )); then
    exit 0
fi

rm -f -- "${artifacts[@]}"
echo "clean-stray-artifacts: removed ${#artifacts[@]} file(s) from project root"
