---
# 20b-1vw
title: 'Correctable lint rule: XCTest assertions → Swift Testing assertions'
status: ready
type: task
priority: normal
created_at: 2026-04-12T02:27:04Z
updated_at: 2026-04-12T02:27:04Z
parent: ogh-b3l
sync:
    github:
        issue_number: "209"
        synced_at: "2026-04-12T03:13:34Z"
---

## Overview

Create a correctable lint rule that flags individual XCTest assertion calls and suggests Swift Testing equivalents. Complements existing `prefer_swift_testing` which only flags `XCTestCase` class declarations.

## Patterns to detect and correct

- [ ] `XCTAssertEqual(a, b)` → `#expect(a == b)`
- [ ] `XCTAssertNotEqual(a, b)` → `#expect(a != b)`
- [ ] `XCTAssertTrue(x)` → `#expect(x)`
- [ ] `XCTAssertFalse(x)` → `#expect(!x)`
- [ ] `XCTAssertNil(x)` → `#expect(x == nil)`
- [ ] `XCTAssertNotNil(x)` → `#expect(x != nil)`
- [ ] `XCTAssertGreaterThan(a, b)` → `#expect(a > b)`
- [ ] `XCTAssertLessThan(a, b)` → `#expect(a < b)`
- [ ] `XCTAssertThrowsError(expr)` → `#expect(throws: SomeError.self) { expr }`
- [ ] `XCTUnwrap(x)` → `try #require(x)`
- [ ] `XCTFail("msg")` → `Issue.record("msg")`
- [ ] `file: StaticString, line: UInt` parameter pattern → `sourceLocation: SourceLocation = #_sourceLocation`

## Notes

- Correctable for simple cases (assertEqual, assertTrue, etc.)
- ThrowsError → #expect(throws:) correction is more complex due to structural change
- XCTUnwrap → try #require is correctable
- The sourceLocation pattern could be a separate rule or bundled here
- Rule ID: `prefer_swift_testing_assertions`
- Scope: `.lint` with `isCorrectable = true`
