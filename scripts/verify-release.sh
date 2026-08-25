#!/usr/bin/env bash
# Launch each packaged sm executable so a missing dynamic library fails the
# release instead of the install. A binary that names a dylib through @rpath
# aborts in dyld before main, and nothing short of a launch detects that.
#
# The launch runs from the directory holding the executable, which is where an
# @loader_path rpath resolves. A dylib sitting elsewhere in the build tree
# therefore cannot mask the fault.
#
# Inputs:
#   $@  paths to executables to launch
#
# Exit status:
#   0  every executable launched
#   1  at least one executable failed to launch
#   2  no argument given
set -euo pipefail

if [[ $# -eq 0 ]]; then
    echo "usage: $(basename "$0") <executable>..." >&2
    exit 2
fi

status=0

for bin in "$@"; do
    if [[ ! -x "${bin}" ]]; then
        echo "FAIL  ${bin}: not an executable file" >&2
        status=1
        continue
    fi

    abs="$(cd "$(dirname "${bin}")" && pwd)/$(basename "${bin}")"

    # dyld writes its abort to stderr, so the redirect keeps the reason.
    if ! output="$(cd "$(dirname "${abs}")" && "${abs}" --version 2>&1)"; then
        echo "FAIL  ${bin}: did not launch" >&2
        echo "${output}" >&2
        rpaths="$(otool -L "${abs}" | awk '/@rpath/ {print "        " $1}')"
        if [[ -n "${rpaths}" ]]; then
            echo "      unresolved @rpath entries:" >&2
            echo "${rpaths}" >&2
        fi
        status=1
        continue
    fi

    echo "ok    ${bin}: ${output}"
done

exit "${status}"
