---
# nnl-svw
title: Redundancy removal rules
status: ready
type: feature
priority: normal
created_at: 2026-04-14T03:18:16Z
updated_at: 2026-04-14T03:18:16Z
parent: 77g-8mh
sync:
    github:
        issue_number: "292"
        synced_at: "2026-04-14T03:28:24Z"
---

Port redundancy-removal rules from SwiftFormat. These detect and remove unnecessary code constructs.

**Implementation**: Pure AST analysis. `SyntaxLintRule` (lint scope, correctable). Visit the relevant syntax node, detect the redundant construct, emit diagnostic with fix-it. Reference SwiftFormat token logic at `~/Developer/swiftiomatic-ref/SwiftFormat/Sources/Rules/` but translate to swift-syntax node matching.

## Rules

- [ ] `redundantAsync` — Remove `async` from functions that contain no `await` expressions
- [ ] `redundantBackticks` — Remove backticks around identifiers when not needed (e.g. `` `name` `` → `name`)
- [ ] `redundantBreak` — Remove `break` at end of switch case when it's the only statement or follows other statements
- [ ] `redundantClosure` — Remove immediately-invoked closures containing a single statement (e.g. `{ return x }()` → `x`)
- [ ] `redundantEquatable` — Omit hand-written `Equatable` when compiler-synthesized conformance is equivalent
- [ ] `redundantExtensionACL` — Remove access control on extension members that match the extension's own ACL
- [ ] `redundantFileprivate` — Prefer `private` over `fileprivate` where equivalent *(extend existing `FileScopedDeclarationPrivacy`)*
- [ ] `redundantInit` — Remove explicit `.init` when type can be inferred (e.g. `Foo.init()` → `Foo()`)
- [ ] `redundantInternal` — Remove `internal` access modifier (it's the default)
- [ ] `redundantLet` — Remove `let _` from ignored variables (e.g. `let _ = foo()` → `_ = foo()`)
- [ ] `redundantLetError` — Remove `let error` from `catch` clauses (error is implicit)
- [ ] `redundantNilInit` — Remove `= nil` from optional var declarations (nil is the default)
- [ ] `redundantObjc` — Remove `@objc` when already implied by other attributes (`@IBAction`, `@IBOutlet`, etc.)
- [ ] `redundantOptionalBinding` — Remove redundant identifier in `if let x = x` → `if let x` (SE-0345)
- [ ] `redundantParens` — Remove redundant parentheses beyond just conditions *(extend existing `NoParensAroundConditions`)*
- [ ] `redundantPattern` — Remove redundant pattern matching (e.g. `case .foo(let _)` → `case .foo(_)` → `case .foo`)
- [ ] `redundantProperty` — Remove property assigned and immediately returned (e.g. `let result = x; return result` → `return x`)
- [ ] `redundantPublic` — Remove `public` on declarations inside `internal` or `private` types where it has no effect
- [ ] `redundantRawValues` — Remove raw values matching enum case name (e.g. `case foo = "foo"` → `case foo`)
- [ ] `redundantSelf` — Insert/remove explicit `self` where applicable (configurable)
- [ ] `redundantSendable` — Remove explicit `Sendable` from non-public structs/enums where inferred
- [ ] `redundantStaticSelf` — Remove `Self.` in static context where type is inferred
- [ ] `redundantThrows` — Remove `throws` from functions that never throw
- [ ] `redundantType` — Remove redundant type annotation when type is obvious from initializer
- [ ] `redundantTypedThrows` — Convert `throws(any Error)` → `throws` and `throws(Never)` → non-throwing
- [ ] `redundantViewBuilder` — Remove `@ViewBuilder` when not needed (single expression body)
