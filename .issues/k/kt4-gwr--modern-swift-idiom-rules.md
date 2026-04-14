---
# kt4-gwr
title: Modern Swift idiom rules
status: in-progress
type: feature
priority: normal
created_at: 2026-04-14T03:18:16Z
updated_at: 2026-04-14T05:06:43Z
parent: 77g-8mh
sync:
    github:
        issue_number: "290"
        synced_at: "2026-04-14T06:15:35Z"
---

Port modern Swift idiom and language-pattern rules from SwiftFormat. These enforce modern Swift conventions and best practices.

**Implementation**: AST analysis with `SyntaxLintRule` (lint scope, mostly correctable). Some may need `.suggest` scope if false-positive rate is high. Reference SwiftFormat implementations at `~/Developer/swiftiomatic-ref/SwiftFormat/Sources/Rules/`.

## Rules

- [x] `acronyms` — Capitalize acronyms when first character is capitalized (e.g. `JsonParser` → `JSONParser`; configurable word list)
- [x] `andOperator` — Prefer comma over `&&` in `if`/`guard`/`while` conditions
- [x] `anyObjectProtocol` — Prefer `AnyObject` over `class` in protocol definitions
- [x] `applicationMain` — Replace `@UIApplicationMain`/`@NSApplicationMain` with `@main` (Swift 5.3+)
- [x] `assertionFailures` — Replace `assert(false, ...)` with `assertionFailure(...)` and `precondition(false, ...)` with `preconditionFailure(...)`
- [ ] `conditionalAssignment` (**blocked**, see c7r-77o) — Use if/switch expressions for assignment (e.g. `let x; if c { x = a } else { x = b }` → `let x = if c { a } else { b }`)
- [x] `enumNamespaces` — Convert types hosting only static members into `enum` (prevents instantiation)
- [ ] `environmentEntry` (**blocked**, see c7r-77o) — Use `@Entry` macro for `EnvironmentValues` definitions
- [x] `genericExtensions` — Use angle brackets for generic extensions (e.g. `extension Array where Element == Foo` → `extension Array<Foo>`)
- [x] `hoistAwait` — Move inline `await` to start of expression
- [x] `hoistTry` — Move inline `try` to start of expression
- [x] `isEmpty` — Prefer `.isEmpty` over `.count == 0` or `.count > 0`
- [ ] `opaqueGenericParameters` (**blocked**, see c7r-77o) — Use `some Protocol` instead of `<T: Protocol>` where applicable
- [x] `preferCountWhere` — Prefer `count(where:)` over `filter(_:).count`
- [x] `preferKeyPath` — Convert trivial `map { $0.foo }` closures to keyPath syntax
- [x] `simplifyGenericConstraints` — Use inline constraints `<T: Foo>` instead of `where T: Foo`
- [ ] `strongifiedSelf` — Remove backticks around `self` in optional unwrap expressions (**blocked**, see c7r-77o)
- [x] `yodaConditions` — Prefer constant on right side of comparisons (e.g. `0 == x` → `x == 0`)
