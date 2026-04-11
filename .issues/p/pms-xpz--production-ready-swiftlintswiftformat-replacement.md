---
# pms-xpz
title: Production-ready SwiftLint/SwiftFormat replacement
status: in-progress
type: epic
priority: high
created_at: 2026-04-10T22:24:48Z
updated_at: 2026-04-10T22:29:24Z
sync:
    github:
        issue_number: "161"
        synced_at: "2026-04-11T01:01:45Z"
---

Address the remaining gaps to make Swiftiomatic a credible drop-in replacement for SwiftLint and SwiftFormat across teams. The rule coverage and core architecture are solid — these issues target the adoption and migration barriers that prevent teams from switching.

## Scope

- Inline suppression comments
- Baseline system for incremental adoption
- Config migration from SwiftLint
- Nested per-directory configuration
- Dry-run diff for `--fix`
- GitHub Actions action
- `.swift-version` file support
