---
# 20b-1vw
title: 'Correctable lint rule: XCTest assertions → Swift Testing assertions'
status: completed
type: task
priority: normal
created_at: 2026-04-12T02:27:04Z
updated_at: 2026-04-12T23:15:41Z
parent: ogh-b3l
sync:
    github:
        issue_number: "209"
        synced_at: "2026-04-12T23:20:53Z"
---

## Overview

Create a correctable lint rule that flags individual XCTest assertion calls and suggests Swift Testing equivalents. Complements existing `prefer_swift_testing` which only flags `XCTestCase` class declarations.

## Patterns to detect and correct

- [x] `XCTAssertEqual(a, b)` → `#expect(a == b)`
- [x] `XCTAssertNotEqual(a, b)` → `#expect(a != b)`
- [x] `XCTAssertTrue(x)` → `#expect(x)`
- [x] `XCTAssertFalse(x)` → `#expect(!x)`
- [x] `XCTAssertNil(x)` → `#expect(x == nil)`
- [x] `XCTAssertNotNil(x)` → `#expect(x != nil)`
- [x] `XCTAssertGreaterThan(a, b)` → `#expect(a > b)`
- [x] `XCTAssertLessThan(a, b)` → `#expect(a < b)`
- [x] `XCTAssertThrowsError(expr)` → `#expect(throws: SomeError.self) { expr }`
- [x] `XCTUnwrap(x)` → `try #require(x)`
- [x] `XCTFail("msg")` → `Issue.record("msg")`
- [ ] `file: StaticString, line: UInt` parameter pattern → `sourceLocation: SourceLocation = #_sourceLocation`

## Notes

- Correctable for simple cases (assertEqual, assertTrue, etc.)
- ThrowsError → #expect(throws:) correction is more complex due to structural change
- XCTUnwrap → try #require is correctable
- The sourceLocation pattern could be a separate rule or bundled here
- Rule ID: `prefer_swift_testing_assertions`
- Scope: `.lint` with `isCorrectable = true`


## Summary of Changes

Created `PreferSwiftTestingAssertionsRule` (lint, correctable) covering 13 XCTest assertion patterns with auto-corrections for 12 of them. `XCTAssertThrowsError` is detected but not auto-corrected due to structural change.

The `sourceLocation` parameter pattern was deferred to a separate rule (different pattern type — parameter signatures vs function calls).
