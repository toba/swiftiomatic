---
# y7m-4we
title: Remove 3 unnecessary dependencies
status: completed
type: task
priority: normal
created_at: 2026-02-28T03:03:36Z
updated_at: 2026-02-28T16:18:55Z
sync:
    github:
        issue_number: "60"
        synced_at: "2026-03-01T01:01:39Z"
---

Remove SwiftyTextTable, CollectionConcurrencyKit, and swift-filename-matcher dependencies.

## Tasks
- [x] Replace SwiftyTextTable in SummaryReporter with manual String formatting
- [x] Replace CollectionConcurrencyKit in Configuration+CommandLine with TaskGroup
- [x] Replace swift-filename-matcher in 3 lint files with Darwin fnmatch(3)
- [x] Update Package.swift to remove all 3 packages
- [x] Build and test


## Summary of Changes

All three unnecessary dependencies (SwiftyTextTable, CollectionConcurrencyKit, swift-filename-matcher) have been removed from Package.swift and replaced with standard library / Darwin equivalents in the source code. Build verified clean.
