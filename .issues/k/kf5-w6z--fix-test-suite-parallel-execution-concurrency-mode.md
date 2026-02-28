---
# kf5-w6z
title: 'Fix test suite: parallel execution + concurrency modernization'
status: in-progress
type: task
created_at: 2026-02-28T06:01:46Z
updated_at: 2026-02-28T06:01:46Z
---

## Plan

### Phase 1: Replace legacy locks with Mutex (Sources/)
- [ ] 1a. SwiftLintFile+Cache.swift — PlatformLock → Mutex
- [ ] 1b. RuleStorage.swift — DispatchQueue → Mutex
- [ ] 1c. LinterCache.swift — NSLock → Mutex
- [ ] 1d. Configuration+Cache.swift — NSLock → Mutex
- [ ] 1e. Configuration+RulesWrapper.swift — NSLock → Mutex
- [ ] 1f. NSRegularExpression+SwiftLint.swift — NSLock → Mutex
- [ ] 1g. CustomRuleTimer.swift — NSLock → Mutex
- [ ] 1h. RuleRegistry.swift — @unchecked Sendable → Mutex
- [ ] 1i. LintOrAnalyzeCommand.swift — DispatchQueue → Mutex
- [ ] 1j. Request+SwiftLint.swift — nonisolated(unsafe) → Mutex
- [ ] 1k. Configuration+Remote.swift — nonisolated(unsafe) → Mutex

### Phase 2: Fix test infrastructure (Tests/)
- [ ] 2a. LintTestHelpers.swift — remove lock, remove clearCaches()
- [ ] 2b. Remove @Suite(.serialized) from all suites
- [ ] 2c. Consolidate duplicated violations() helpers
- [ ] 2d. FormatTestHelper.swift — eager global init

### Phase 3: Verify
- [ ] swift build succeeds
- [ ] swift test succeeds
