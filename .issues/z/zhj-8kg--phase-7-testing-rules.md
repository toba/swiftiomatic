---
# zhj-8kg
title: 'Phase 7: Testing rules'
status: ready
type: task
priority: normal
created_at: 2026-04-14T18:37:26Z
updated_at: 2026-04-14T18:37:26Z
parent: c7r-77o
sync:
    github:
        issue_number: "306"
        synced_at: "2026-04-14T18:45:55Z"
---

Complex testing-related rules that require expression-level analysis or full framework migration. From m0v-ruy.

- [ ] `noForceUnwrapInTests` — Replace `!` with `XCTUnwrap`/`#require` wrapping. Requires expression-range parsing, `as!`→`as?` conversion, LHS/RHS analysis, standalone-expression detection. 350+ lines in SwiftFormat. Parent: m0v-ruy.
- [ ] `noGuardInTests` — Convert `guard` to `try #require`/`#expect`. Requires guard condition parsing, variable shadowing detection, building multi-statement replacements. 250 lines in SwiftFormat. Parent: m0v-ruy.
- [ ] `preferSwiftTesting` — Full XCTest→Swift Testing migration. Import rewriting, assertion conversion (`XCTAssert*`→`#expect`), `setUp`/`tearDown`→`init`/`deinit`, conformance removal. 600+ lines in SwiftFormat. Parent: m0v-ruy.
