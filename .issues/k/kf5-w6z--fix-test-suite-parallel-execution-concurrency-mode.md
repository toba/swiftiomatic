---
# kf5-w6z
title: 'Fix test suite: parallel execution + concurrency modernization'
status: completed
type: task
priority: normal
created_at: 2026-02-28T06:01:46Z
updated_at: 2026-02-28T16:19:43Z
sync:
    github:
        issue_number: "17"
        synced_at: "2026-03-01T01:01:31Z"
---

## Plan

### Phase 1: Replace legacy locks with Mutex (Sources/)
- [x] 1a. SwiftSource+Cache.swift — PlatformLock → Mutex
- [x] 1b. RuleStorage.swift — DispatchQueue → Mutex
- [x] 1c. LinterCache.swift — NSLock → Mutex
- [x] 1d. Configuration+Cache.swift — NSLock → Mutex
- [x] 1e. Configuration+RulesWrapper.swift — NSLock → Mutex
- [x] 1f. NSRegularExpression+SwiftLint.swift — NSLock → Mutex
- [x] 1g. CustomRuleTimer.swift — NSLock → Mutex
- [x] 1h. RuleRegistry.swift — @unchecked Sendable → Mutex
- [x] 1i. LintOrAnalyzeCommand.swift — DispatchQueue → Mutex
- [x] 1j. Request+SwiftLint.swift — nonisolated(unsafe) → Mutex
- [x] 1k. Configuration+Remote.swift — nonisolated(unsafe) → Mutex

### Phase 2: Fix test infrastructure (Tests/)
- [x] 2a. LintTestHelpers.swift — remove lock, remove clearCaches()
- [x] 2b. Remove @Suite(.serialized) from all suites
- [x] 2c. Consolidate duplicated violations() helpers
- [x] 2d. FormatTestHelper.swift — eager global init

### Phase 3: Verify
- [x] swift build succeeds
- [x] swift test succeeds


## Summary of Changes

All legacy locks (NSLock, PlatformLock, DispatchQueue-as-mutex, nonisolated(unsafe), @unchecked Sendable) replaced with Mutex from Synchronization framework. Test infrastructure modernized: removed serialization, removed clearCaches(), consolidated helpers, eager global init for format tests. Parallel test execution enabled.
