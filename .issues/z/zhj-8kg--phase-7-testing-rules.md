---
# zhj-8kg
title: 'Phase 7: Testing rules'
status: completed
type: task
priority: normal
created_at: 2026-04-14T18:37:26Z
updated_at: 2026-04-14T22:41:17Z
parent: c7r-77o
sync:
    github:
        issue_number: "306"
        synced_at: "2026-04-15T00:34:45Z"
---

Complex testing-related rules that require expression-level analysis or full framework migration. From m0v-ruy.

- [x] `noForceUnwrapInTests` — Replace `!` with `XCTUnwrap`/`#require` wrapping. Requires expression-range parsing, `as!`→`as?` conversion, LHS/RHS analysis, standalone-expression detection. 350+ lines in SwiftFormat. Parent: m0v-ruy.
- [x] `noGuardInTests` — Convert `guard` to `try #require`/`#expect`. Requires guard condition parsing, variable shadowing detection, building multi-statement replacements. 250 lines in SwiftFormat. Parent: m0v-ruy.
- [x] `preferSwiftTesting` — Full XCTest→Swift Testing migration. Import rewriting, assertion conversion (`XCTAssert*`→`#expect`), `setUp`/`tearDown`→`init`/`deinit`, conformance removal. 600+ lines in SwiftFormat. Parent: m0v-ruy.


## Summary of Changes

Implemented all 3 testing rules as format rules with auto-fix:

- **`noGuardInTests`** (51 tests) — Convert `guard` in test functions to `try #require`/`#expect` (Swift Testing) or `try XCTUnwrap`/`XCTAssert` (XCTest). Handles multiple conditions, boolean conditions, shadowing detection, type annotations, shorthand binding, message preservation.

- **`noForceUnwrapInTests`** (25 tests) — Replace force unwraps (`!`) with `try XCTUnwrap`/`try #require`. Uses chain-top wrapping pattern: converts inner `!` to `?`, wraps at chain top. Handles `as!` → `as?`, assignment LHS, equality, XCTAssertEqual/Nil, standalone calls, function args, return statements, string interpolation/closure/nested function exclusion.

- **`preferSwiftTesting`** (18 tests) — Full XCTest → Swift Testing migration. Replaces `import XCTest` → `import Testing`, removes XCTestCase conformance, converts setUp→init / tearDown→deinit (with super call removal), adds `@Test` to test methods, converts 9 assertion types (XCTAssert/True/False/Nil/NotNil/Equal/NotEqual/Fail/Unwrap). Bails out for unsupported patterns (expectations, measure, async tearDown, unknown overrides).

All rules are opt-in. New /rule skill patterns documented: chain-top wrapping, AssignmentExprSyntax vs BinaryOperatorExprSyntax, flag save/restore.
