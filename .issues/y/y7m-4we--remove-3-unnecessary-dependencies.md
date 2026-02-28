---
# y7m-4we
title: Remove 3 unnecessary dependencies
status: in-progress
type: task
created_at: 2026-02-28T03:03:36Z
updated_at: 2026-02-28T03:03:36Z
---

Remove SwiftyTextTable, CollectionConcurrencyKit, and swift-filename-matcher dependencies.

## Tasks
- [ ] Replace SwiftyTextTable in SummaryReporter with manual String formatting
- [ ] Replace CollectionConcurrencyKit in Configuration+CommandLine with TaskGroup
- [ ] Replace swift-filename-matcher in 3 lint files with Darwin fnmatch(3)
- [ ] Update Package.swift to remove all 3 packages
- [ ] Build and test
