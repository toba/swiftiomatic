---
# wg6-4jd
title: Migrate API tests to Swift Testing
status: completed
type: task
priority: normal
created_at: 2026-04-14T02:53:02Z
updated_at: 2026-04-14T03:14:58Z
parent: rwb-wt3
sync:
    github:
        issue_number: "276"
        synced_at: "2026-04-14T03:28:23Z"
---

Convert 2 standalone test files in `Tests/SwiftiomaticTests/API/` from XCTest to Swift Testing.

## Files

- [ ] `ConfigurationTests.swift` — 6 tests, uses `XCTAssertNil`, `XCTAssertEqual`, `JSONDecoder`
- [ ] `SwiftFormatterSelectionTests.swift` — 11 tests, has private `assertFormatting` helper with `file: StaticString = #file, line: UInt = #line`

## Conversion Plan

1. Replace `import XCTest` with `import Testing`
2. Replace `final class FooTests: XCTestCase` with `@Suite struct FooTests`
3. Replace `func testFoo()` with `@Test func foo()`
4. Assertion mapping (standard)
5. **SwiftFormatterSelectionTests special case**: the private `assertFormatting` helper passes `file:line:` to `XCTAssertEqual`. Convert to:
   ```swift
   private func assertFormatting(
       ...,
       sourceLocation: SourceLocation = #_sourceLocation
   ) throws {
       #expect(result == expected, sourceLocation: sourceLocation)
   }
   ```
