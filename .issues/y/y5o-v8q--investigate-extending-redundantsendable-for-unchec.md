---
# y5o-v8q
title: Investigate extending RedundantSendable for @unchecked Sendable
status: scrapped
type: feature
priority: normal
created_at: 2026-04-30T23:13:50Z
updated_at: 2026-04-30T23:17:35Z
parent: 7h4-72k
sync:
    github:
        issue_number: "588"
        synced_at: "2026-04-30T23:23:59Z"
---

Originally part of epic 7h4-72k. Extend `Sources/SwiftiomaticKit/Rules/Redundancies/RedundantSendable.swift` to also strip `@unchecked Sendable` when:

(a) all stored fields are themselves `Sendable`, or
(b) the only "unsafe" storage is `[any P.Type]` where `P: Sendable` (SE-0470 metatype storage)

The current rule handles redundant `: Sendable` on non-public structs/enums but doesn't touch `@unchecked` cases. Investigate scope: how much of (a) needs cross-decl/type-info to be safe, vs. how much can be detected structurally.

## Plan

- [ ] Survey `@unchecked Sendable` patterns in the wild
- [ ] Identify the safe structural subset (fields with literal Sendable types, primitive types, etc.)
- [ ] Decide whether (a) and (b) are doable without semantic info
- [ ] If yes, implement; if no, scrap with notes



## Reasons for Scrapping

Investigation outcome: neither (a) nor (b) is doable structurally without semantic type information. The structurally-safe subset is too narrow to justify the rule.

**Findings:**

- Reference linters (SwiftFormat, SwiftLint, swift-format) all have an equivalent `RedundantSendable` rule, and **none** of them touch `@unchecked Sendable` — every test case preserves it. No precedent exists for this transformation.
- Real-world `@unchecked Sendable` storage patterns surveyed in the ref repos and this codebase are dominated by cases that require semantic info: `NSLock` / `Mutex<T>` / `OSAllocatedUnfairLock` guarding mutable state, `UnsafeBuffer*Pointer` / raw pointers, classes subclassing a non-Sendable base (`SyntaxVisitor`, `SyntaxRewriter`), and `[any P.Type]` metatype storage.

**Case (a) — all fields Sendable:** Requires knowing every field's declared type and its `Sendable` conformance. Structurally we can only recognize a hard-coded allow-list of stdlib primitives. The moment a custom type appears we have to bail. Authors writing `@unchecked` almost always do so because the compiler couldn't infer Sendable — exactly the case we also cannot verify structurally. The rule would virtually never fire on real code.

**Case (b) — `[any P.Type]` metatype (SE-0470):** Detectable only if `P` is a hard-coded known-Sendable name (literally `Sendable`). In practice authors write `[any Rule.Type]`, `[any Codable.Type]`, etc. — `P`'s Sendable status is semantic. The codebase itself uses `nonisolated(unsafe)` for `RuleBasedFindingCategory.ruleType: any Rule.Type` because `Rule` does not conform to `Sendable` (see g2k-uar) — i.e., the case where `@unchecked` is **not** redundant.

**Risk:** A structural false-positive stripping `@unchecked Sendable` from a class with hidden mutable state or non-Sendable generic parameters either breaks the build or, worse, silently introduces a data race. Wrong fixes are high-cost.

**Possible follow-ups (deferred):**

- A lint-only advisory (no rewrite) that flags `@unchecked Sendable` declarations whose body looks structurally safe (final class / struct / enum with only `let`-declared primitive-typed fields). Low risk because no automatic fix.
- Revisit (a) + (b) properly once Swiftiomatic gains semantic analysis.
