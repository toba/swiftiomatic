---
# m0v-ruy
title: Testing rules
status: ready
type: feature
priority: normal
created_at: 2026-04-14T03:18:17Z
updated_at: 2026-04-14T03:18:17Z
parent: 77g-8mh
sync:
    github:
        issue_number: "288"
        synced_at: "2026-04-14T03:28:23Z"
---

Port testing-related rules from SwiftFormat. These enforce best practices in test code for both XCTest and Swift Testing.

**Implementation**: `SyntaxLintRule` (lint scope). Need to detect test context: check for `@Test`/`@Suite` attributes, `XCTestCase` subclass, or test target file paths. Some rules are correctable (can auto-fix).

## Rules

- [ ] `noForceTryInTests` — Use `throws` on test methods instead of `try!`
- [ ] `noForceUnwrapInTests` — Use `try #require(x)` (Swift Testing) or `XCTUnwrap` instead of `x!`
- [ ] `noGuardInTests` — Convert `guard` in tests to `try #require(...)` / `#expect(...)` or `XCTUnwrap`/`XCTAssert`
- [ ] `preferSwiftTesting` — Prefer Swift Testing (`@Test`, `#expect`) over XCTest (`XCTestCase`, `XCTAssert*`)
- [ ] `redundantSwiftTestingSuite` — Remove `@Suite` with no arguments (it's inferred)
- [ ] `swiftTestingTestCaseNames` — Format Swift Testing `@Test` and `@Suite` display names consistently
- [ ] `testSuiteAccessControl` — Test methods should be `internal`; helper properties/functions should be `private`
- [ ] `throwingTests` — Test methods should use `throws` instead of `try!` (broader than `noForceTryInTests`)
- [ ] `validateTestCases` — Ensure test methods have correct `test` prefix or `@Test` attribute
