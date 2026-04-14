---
# v6s-twz
title: Migrate Core tests to Swift Testing
status: ready
type: task
priority: normal
created_at: 2026-04-14T02:53:02Z
updated_at: 2026-04-14T02:53:02Z
parent: rwb-wt3
sync:
    github:
        issue_number: "270"
        synced_at: "2026-04-14T02:58:30Z"
---

Convert 3 standalone test files in `Tests/SwiftiomaticTests/Core/` from XCTest to Swift Testing. These have no base class dependency — they extend `XCTestCase` directly.

## Files

- [ ] `RuleMaskTests.swift` — 15 tests, uses `XCTAssertEqual` (~50 calls), helper methods `createMask()` and `location()`
- [ ] `DocumentationCommentTests.swift` — 11 tests, uses `XCTUnwrap`, `XCTAssertEqual`, `XCTAssertNil`, `XCTAssertTrue`
- [ ] `DocumentationCommentTextTests.swift` — uses `XCTAssertEqual`

## Conversion Plan

1. Replace `import XCTest` with `import Testing`
2. Replace `final class FooTests: XCTestCase` with `@Suite struct FooTests`
3. Replace `func testFoo()` with `@Test func foo()`
4. Assertion mapping:
   - `XCTAssertEqual(a, b)` → `#expect(a == b)`
   - `XCTAssertNil(x)` → `#expect(x == nil)`
   - `XCTAssertNotNil(x)` → `#expect(x != nil)`
   - `XCTAssertTrue(x)` → `#expect(x)`
   - `try XCTUnwrap(x)` → `try #require(x)`
5. No setUp/tearDown needed — these tests are stateless
