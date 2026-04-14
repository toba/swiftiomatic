---
# m0v-ruy
title: Testing rules
status: in-progress
type: feature
priority: normal
created_at: 2026-04-14T03:18:17Z
updated_at: 2026-04-14T18:30:18Z
parent: 77g-8mh
sync:
    github:
        issue_number: "288"
        synced_at: "2026-04-14T18:45:51Z"
---

Port testing-related rules from SwiftFormat. These enforce best practices in test code for both XCTest and Swift Testing.

**Implementation**: `SyntaxLintRule` (lint scope). Need to detect test context: check for `@Test`/`@Suite` attributes, `XCTestCase` subclass, or test target file paths. Some rules are correctable (can auto-fix).

## Rules

- [x] `noForceTryInTests` — Use `throws` on test methods instead of `try!`
- [ ] `noForceUnwrapInTests` — **Blocked** (see c7r-77o Phase 7). Use `try #require(x)` (Swift Testing) or `XCTUnwrap` instead of `x!`
- [ ] `noGuardInTests` — **Blocked** (see c7r-77o Phase 7). Convert `guard` in tests to `try #require(...)` / `#expect(...)` or `XCTUnwrap`/`XCTAssert`
- [ ] `preferSwiftTesting` — **Blocked** (see c7r-77o Phase 7). Prefer Swift Testing (`@Test`, `#expect`) over XCTest (`XCTestCase`, `XCTAssert*`)
- [x] `redundantSwiftTestingSuite` — Remove `@Suite` with no arguments (it's inferred)
- [x] `swiftTestingTestCaseNames` — Format Swift Testing `@Test` and `@Suite` display names consistently
- [x] `testSuiteAccessControl` — Test methods should be `internal`; helper properties/functions should be `private`
- [x] `throwingTests` — deprecated alias for `noForceTryInTests`, skipped — Test methods should use `throws` instead of `try!` (broader than `noForceTryInTests`)
- [x] `validateTestCases` — Ensure test methods have correct `test` prefix or `@Test` attribute
