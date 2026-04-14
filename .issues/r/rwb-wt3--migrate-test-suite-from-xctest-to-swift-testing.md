---
# rwb-wt3
title: Migrate test suite from XCTest to Swift Testing
status: completed
type: epic
priority: high
created_at: 2026-04-14T02:41:43Z
updated_at: 2026-04-14T03:24:20Z
sync:
    github:
        issue_number: "265"
        synced_at: "2026-04-14T03:28:22Z"
---

Migrate the entire test suite (124 files, 0% Swift Testing) to Swift Testing (`@Test`, `#expect`, `#require`). The only exception is `WhitespaceLinterPerformanceTests` which must remain XCTest due to `measure()`.

## Current State

| Folder | Files | Base Class | Framework |
|--------|-------|-----------|-----------|
| PrettyPrint/ | 71 | PrettyPrintTestCase, WhitespaceTestCase | XCTest |
| Rules/ | 45 | LintOrFormatRuleTestCase | XCTest |
| Core/ | 3 | XCTestCase (direct) | XCTest |
| API/ | 2 | XCTestCase (direct) | XCTest |
| Utilities/ | 2 | XCTestCase (direct) | XCTest |
| PerformanceTests/ | 1 | DiagnosingTestCase | XCTest (keep) |

## Class Hierarchy

```
XCTestCase
  └─ DiagnosingTestCase (_SwiftiomaticTestSupport)
       ├─ PrettyPrintTestCase
       │    └─ 69 pretty-print test classes
       ├─ WhitespaceTestCase
       │    └─ 2 whitespace test classes
       ├─ LintOrFormatRuleTestCase
       │    └─ 44 rule test classes
       └─ WhitespaceLinterPerformanceTests (keep XCTest)
```

## Tricky Conversion Patterns

### 1. Custom Base Class Hierarchy → TestScoping Traits + Free Functions
XCTest classes with shared helpers can't become `@Suite struct` directly. Strategy:
- Extract assertion helpers to free functions with `sourceLocation: SourceLocation = #_sourceLocation`
- Use `TestScoping` traits for setUp/tearDown lifecycle
- Test suites become `@Suite struct` with `@Test func` methods

### 2. file:/line: → sourceLocation:
All helpers chain `file: StaticString = #file, line: UInt = #line`. Must collapse to single `sourceLocation: SourceLocation = #_sourceLocation` parameter throughout the entire helper chain.

### 3. setUp/tearDown → init/TestScoping
- `FileIteratorTests.setUp()`: creates temp directory with symlinks → `TestScoping` trait with cleanup
- `GeneratedFilesValidityTests.setUp()`: creates `RuleCollector` → simple `init()`
- `BeginDocumentationCommentWithOneLineSummaryTests.setUp()`: resets static flag → `TestScoping` trait

### 4. XCTFail → Issue.record
`assertFindings()` and `assertStringsEqualWithDiff()` use `XCTFail` for detailed failure messages. Replace with `Issue.record("msg", sourceLocation:)`.

### 5. measure() — No Equivalent
`WhitespaceLinterPerformanceTests` must remain XCTest. It uses `measure {}` for performance benchmarking. Swift Testing has no performance measurement API.

## Execution Order

Phase 1 (parallel, no dependencies): Core, API, Utilities tests
Phase 2 (blocker): _SwiftiomaticTestSupport infrastructure
Phase 3 (depends on Phase 2): PrettyPrint tests, Rules tests

## Reasons for Scrapping

Covered by a different epic.
