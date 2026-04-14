---
# tto-2t6
title: Migrate Utilities tests to Swift Testing
status: completed
type: task
priority: normal
created_at: 2026-04-14T02:53:02Z
updated_at: 2026-04-14T03:14:58Z
parent: rwb-wt3
sync:
    github:
        issue_number: "271"
        synced_at: "2026-04-14T03:28:23Z"
---

Convert 2 test files in `Tests/SwiftiomaticTests/Utilities/` from XCTest to Swift Testing. These extend `XCTestCase` directly but have setUp/tearDown lifecycle.

## Files

- [ ] `FileIteratorTests.swift` — 10 tests, uses setUp/tearDown for temp directory management
- [ ] `GeneratedFilesValidityTests.swift` — 4 tests, uses setUp to create `RuleCollector`

## Conversion Plan

### FileIteratorTests (setUp/tearDown → TestScoping trait)

This test creates a temp directory with symlinks in `setUpWithError()` and cleans up in `tearDownWithError()`. Use a `TestScoping` trait:

```swift
struct TempDirectoryTrait: TestTrait, TestScoping {
    func provideScope(
        for test: Test,
        testCase: Test.Case?,
        performing function: @concurrent @Sendable () async throws -> Void
    ) async throws {
        // create temp dir
        try await function()
        // cleanup temp dir
    }
}
```

Alternative (simpler): since each test needs its own temp dir, make the struct hold a computed `tmpdir` and set it up in `init()`. But cleanup is the tricky part — `TestScoping` is cleaner.

**Note:** The temp directory setup creates symlinks (including cycles) — this must work in Swift Testing's concurrent test environment. Each test should get its own isolated temp directory.

### GeneratedFilesValidityTests (setUp → init)

Simple: `ruleCollector` created in setUp can move to a stored property initialized inline:

```swift
@Suite struct GeneratedFilesValidityTests {
    let ruleCollector: RuleCollector

    init() throws {
        ruleCollector = RuleCollector()
        try ruleCollector.collect(from: GenerateSwiftiomaticPaths.rulesDirectory)
    }
}
```
