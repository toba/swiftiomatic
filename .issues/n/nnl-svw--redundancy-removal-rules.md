---
# nnl-svw
title: Redundancy removal rules
status: completed
type: feature
priority: normal
created_at: 2026-04-14T03:18:16Z
updated_at: 2026-04-14T04:46:08Z
parent: 77g-8mh
sync:
    github:
        issue_number: "292"
        synced_at: "2026-04-14T06:15:35Z"
---

Port redundancy-removal rules from SwiftFormat. These detect and remove unnecessary code constructs.

**Implementation**: Pure AST analysis. `SyntaxLintRule` (lint scope, correctable). Visit the relevant syntax node, detect the redundant construct, emit diagnostic with fix-it. Reference SwiftFormat token logic at `~/Developer/swiftiomatic-ref/SwiftFormat/Sources/Rules/` but translate to swift-syntax node matching.

## Rules

- [x] `redundantAsync` — Remove `async` from functions that contain no `await` expressions
- [x] `redundantBackticks` — Remove backticks around identifiers when not needed (e.g. `` `name` `` → `name`)
- [x] `redundantBreak` — Remove `break` at end of switch case when it's the only statement or follows other statements
- [x] `redundantClosure` — Remove immediately-invoked closures containing a single statement (e.g. `{ return x }()` → `x`)
- [x] `redundantEquatable` — Omit hand-written `Equatable` when compiler-synthesized conformance is equivalent
- [x] `redundantExtensionACL` — Remove access control on extension members that match the extension's own ACL
- [x] `redundantFileprivate` — deferred to c7r-77o
- [x] `redundantInit` — Remove explicit `.init` when type can be inferred (e.g. `Foo.init()` → `Foo()`)
- [x] `redundantInternal` — Remove `internal` access modifier (it's the default)
- [x] `redundantLet` — Remove `let _` from ignored variables (e.g. `let _ = foo()` → `_ = foo()`)
- [x] `redundantLetError` — Remove `let error` from `catch` clauses (error is implicit)
- [x] `redundantNilInit` — Remove `= nil` from optional var declarations (nil is the default)
- [x] `redundantObjc` — Remove `@objc` when already implied by other attributes (`@IBAction`, `@IBOutlet`, etc.)
- [x] `redundantOptionalBinding` — Remove redundant identifier in `if let x = x` → `if let x` (SE-0345)
- [x] `redundantParens` — deferred to c7r-77o
- [x] `redundantPattern` — deferred to c7r-77o
- [x] `redundantProperty` — Remove property assigned and immediately returned (e.g. `let result = x; return result` → `return x`)
- [x] `redundantPublic` — Remove `public` on declarations inside `internal` or `private` types where it has no effect
- [x] `redundantRawValues` — Remove raw values matching enum case name (e.g. `case foo = "foo"` → `case foo`)
- [x] `redundantSelf` — deferred to c7r-77o
- [x] `redundantSendable` — Remove explicit `Sendable` from non-public structs/enums where inferred
- [x] `redundantStaticSelf` — Remove `Self.` in static context where type is inferred
- [x] `redundantThrows` — Remove `throws` from functions that never throw
- [x] `redundantType` — Remove redundant type annotation when type is obvious from initializer
- [x] `redundantTypedThrows` — Convert `throws(any Error)` → `throws` and `throws(Never)` → non-throwing
- [x] `redundantViewBuilder` — Remove `@ViewBuilder` when not needed (single expression body)


## Summary of Changes

Implemented 22 redundancy-removal rules (171 tests total). 4 rules deferred to c7r-77o due to architectural complexity or swift-syntax limitations.

**Format rules** (auto-fix): RedundantNilInit, RedundantLetError, RedundantInternal, RedundantRawValues, RedundantOptionalBinding, RedundantInit

**Lint rules**: RedundantLet, RedundantBreak, RedundantObjc, RedundantProperty, RedundantType, RedundantTypedThrows, RedundantBackticks, RedundantClosure, RedundantExtensionACL, RedundantPublic, RedundantAsync, RedundantThrows, RedundantSendable, RedundantEquatable

**Opt-in lint rules**: RedundantViewBuilder, RedundantStaticSelf

**Deferred to c7r-77o**: redundantPattern, redundantFileprivate, redundantParens, redundantSelf
