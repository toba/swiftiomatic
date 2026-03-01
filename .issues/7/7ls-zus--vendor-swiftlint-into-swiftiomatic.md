---
# 7ls-zus
title: Vendor SwiftLint into Swiftiomatic
status: completed
type: epic
priority: normal
created_at: 2026-02-27T23:03:25Z
updated_at: 2026-02-27T23:33:16Z
sync:
    github:
        issue_number: "12"
        synced_at: "2026-03-01T01:01:31Z"
---

Vendor SwiftLint 0.63.2 source into Swiftiomatic as a `lint` subcommand.

## Phases
- [x] Phase 1: Upgrade dependencies (swift-syntax 604, Yams 6, SourceKitten 0.37) & fix breakage
- [x] Phase 2: Vendor SwiftLint source (Core + BuiltInRules into Sources/Lint/)
- [x] Phase 3: Bridge layer + `lint` subcommand
- [x] Phase 4: Licensing, citation, docs


## Summary of Changes

SwiftLint 0.63.2 fully vendored. All 4 phases completed across children gd2-ul1, f01-1e6, hmy-th0, lc8-miw.
