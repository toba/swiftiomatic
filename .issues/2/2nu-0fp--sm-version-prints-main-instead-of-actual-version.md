---
# 2nu-0fp
title: sm --version prints "main" instead of actual version
status: completed
type: bug
priority: normal
created_at: 2026-04-25T02:06:52Z
updated_at: 2026-04-25T02:16:28Z
sync:
    github:
        issue_number: "396"
        synced_at: "2026-04-25T02:39:17Z"
---

\`printVersionInformation()\` in \`Sources/Swiftiomatic/PrintVersion.swift\` hardcodes \`print("main")\` instead of reporting the actual version.

The version should come from the git tag (e.g., \`v0.31.12\`) or the Homebrew Cellar path. Options:
1. Use \`git describe --tags\` at build time via a generated file or build plugin
2. Read the Cellar path at runtime (\`/opt/homebrew/Cellar/sm/<version>/\`)
3. Embed version via a Swift compiler flag (\`-Xswiftc -DVERSION=...\`)

See also: issue 0w5-3pm (referenced in the file) for unifying version across CLI, app, and extension.

**File:** \`Sources/Swiftiomatic/PrintVersion.swift:15\`


## Summary of Changes

Added `Sources/Swiftiomatic/Version.swift` with `let smVersion = "0.31.12"` as the single source of truth. `PrintVersion.swift` now prints `smVersion` instead of hardcoded "main". Both `install.sh` and `release.yml` auto-update `Version.swift` via `sed` before building, keeping it in sync with git tags.
