#!/usr/bin/env bash
# Package the release sm binary as an SPM artifact bundle suitable for use
# from a .binaryTarget in toba/swiftiomatic-plugins.
#
# Inputs:
#   $1 (optional) version string (default: derived from Sources/Swiftiomatic/Version.swift)
#
# Outputs:
#   build/sm.artifactbundle/                staging directory
#   build/sm.artifactbundle.zip             release asset
#   build/sm.artifactbundle.zip.sha256      checksum line "<sha>  <filename>"
#
# Assumes the release binary has already been produced under .build/release/sm.
set -euo pipefail

cd "$(dirname "$0")/.."

if [[ $# -ge 1 ]]; then
    version="$1"
else
    version="$(awk -F'"' '/let smVersion/ {print $2}' Sources/Swiftiomatic/Version.swift)"
fi

if [[ -z "${version}" ]]; then
    echo "ERROR: could not determine version" >&2
    exit 1
fi

bin_path=".build/release/sm"
if [[ ! -f "${bin_path}" ]]; then
    # Fall back to the arch-specific path used by SPM on macOS.
    alt_path=".build/arm64-apple-macosx/release/sm"
    if [[ -f "${alt_path}" ]]; then
        bin_path="${alt_path}"
    else
        echo "ERROR: sm not found at ${bin_path} nor ${alt_path} - build the release product first" >&2
        exit 1
    fi
fi

bundle_root="build/sm.artifactbundle"
rm -rf "${bundle_root}" "build/sm.artifactbundle.zip" "build/sm.artifactbundle.zip.sha256"
mkdir -p "${bundle_root}/sm-${version}-macos/bin"

cat > "${bundle_root}/info.json" <<JSON_EOF
{
    "schemaVersion": "1.0",
    "artifacts": {
        "sm": {
            "type": "executable",
            "version": "${version}",
            "variants": [
                {
                    "path": "sm-${version}-macos/bin/sm",
                    "supportedTriples": ["arm64-apple-macosx"]
                }
            ]
        }
    }
}
JSON_EOF

cp "${bin_path}" "${bundle_root}/sm-${version}-macos/bin/sm"
chmod +x "${bundle_root}/sm-${version}-macos/bin/sm"
cp LICENSE.txt "${bundle_root}/LICENSE.txt"

(cd build && zip -r -q sm.artifactbundle.zip sm.artifactbundle)
shasum -a 256 build/sm.artifactbundle.zip | awk -v f="sm.artifactbundle.zip" '{print $1"  "f}' \
    > build/sm.artifactbundle.zip.sha256

echo "version:  ${version}"
echo "bundle:   build/sm.artifactbundle.zip"
echo "sha256:   $(awk '{print $1}' build/sm.artifactbundle.zip.sha256)"
