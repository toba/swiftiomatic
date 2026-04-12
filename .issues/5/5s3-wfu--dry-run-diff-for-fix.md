---
# 5s3-wfu
title: Dry-run diff for --fix
status: completed
type: feature
priority: normal
created_at: 2026-04-10T22:25:29Z
updated_at: 2026-04-12T02:22:10Z
parent: pms-xpz
sync:
    github:
        issue_number: "170"
        synced_at: "2026-04-12T03:13:34Z"
---

Show a unified diff of what \`--fix\` would change without modifying files. This lets teams review auto-corrections before applying them.

```bash
# Show diff without applying
swiftiomatic analyze Sources/ --fix --dry-run

# Apply after review
swiftiomatic analyze Sources/ --fix
```

## Tasks

- [x] Add \`--dry-run\` flag to analyze and format commands
- [x] Capture before/after content for each file during correction pass
- [x] Output unified diff format to stdout
- [x] Support \`--format json\` for dry-run (include diff per file in JSON output)
- [x] Exit with non-zero status if changes would be made (useful for CI)
- [x] Add tests for diff output


## Summary of Changes

Added `--dry-run` flag to both `analyze --fix` and `format` commands. When used, corrections run normally but file contents are saved beforehand and restored afterward. Unified diffs are generated comparing original vs. corrected content and output to stdout (text or JSON). Exit code 1 signals changes would be made (CI-friendly).

### Files changed
- `Sources/SwiftiomaticKit/Support/UnifiedDiff.swift` — new diff engine using `CollectionDifference`
- `Sources/SwiftiomaticCLI/SwiftiomaticCLI.swift` — `--dry-run` flag on `analyze` (requires `--fix`)
- `Sources/SwiftiomaticCLI/FormatCommand.swift` — `--dry-run` flag on `format` (mutually exclusive with `--check`/`--lint`)
- `Sources/GeneratePipeline/RegistryEmitter.swift` — fix missing `import SwiftiomaticSyntax` in generated file
- `Tests/SwiftiomaticTests/Support/UnifiedDiffTests.swift` — 10 tests for diff generation and JSON encoding
