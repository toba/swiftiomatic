---
# 7h4-72k
title: Lint/rewrite rules for mechanically checkable Swift skill guidance
status: ready
type: epic
priority: high
created_at: 2026-04-30T16:14:45Z
updated_at: 2026-04-30T16:19:23Z
sync:
    github:
        issue_number: "537"
        synced_at: "2026-04-30T16:27:52Z"
---

The `/swift` skill (`~/.claude/skills/swift/SKILL.md`) catalogs many patterns that Swiftiomatic could detect (lint) or fix (rewrite) automatically. This epic groups concrete rule candidates derived from §2–§6a + §9. Each child issue should: (1) write a failing test reproducing the pattern, (2) implement a `LintSyntaxRule` and/or `StaticFormatRule`/`StructuralFormatRule`, (3) wire into config + schema.

## Trivially mechanical (lint + autofix)

- [ ] `@_cdecl` → `@c` (Swift 6.3 official spelling)
- [ ] `@_specialize` → `@specialize`
- [ ] `weak var` never reassigned after `init` → `weak let` (SE-0481)
- [ ] `@MainActor` on `View` conformance — remove (already implied)
- [ ] Empty/single-element array literals (`[]`, `[x]`) passed to `some Collection` / `some Sequence` / `any Collection` / `any Sequence` parameters → `EmptyCollection()` / `CollectionOfOne(x)`
- [ ] `Date()` used purely for elapsed-time measurement (`Date().timeIntervalSince(start)`) → `ContinuousClock.now` + `duration(to:)`
- [ ] `if !array.contains(x) { array.append(x) }` → suggest `OrderedSet` (lint only; rewrite risky)
- [ ] Selector-based `addObserver(self, selector:, name:, object:)` → closure-based `addObserver(forName:object:queue:using:)` (lint; rewrite if `@objc` handler is single-use)

## Structurally detectable (lint; rewrite case-by-case)

- [ ] `withObservationTracking` with recursive `onChange` calling its own enclosing function → `Observations` AsyncSequence
- [ ] `AsyncStream { continuation in ... }` body that calls `yield` but never `finish()` and has no `onTermination` — flag missing cleanup
- [ ] `withLock { ... await ... }` — Mutex held across `await` (deadlock/blocking risk)
- [ ] Nested `withLock` on the same mutex
- [ ] Mutation of the iterated collection inside a `for-in` loop (`remove(at:)`, `insert`, `append` on the loop subject)
- [ ] `Data.dropFirst()` / `Data.prefix()` inside a `while`/`for` loop body
- [ ] `NumberFormatter()` / `DateFormatter()` / `MeasurementFormatter()` constructed inside a SwiftUI `body` or computed view property
- [ ] `.sorted(by:)` / `.filter { }` inline inside `ForEach` data argument
- [ ] `id: \.self` in `ForEach` over a non-`Hashable & Stable` value type (best-effort heuristic)
- [ ] `Task { }` inside `@IBAction` / `@MainActor` callback body that does MainActor work first → `Task.immediate` (suggestion-level)
- [ ] `Task.detached` whose body reads a `@TaskLocal` (semantic bug — drops to default)
- [ ] **Extend `RedundantSendable`** (`Sources/SwiftiomaticKit/Rules/Redundancies/RedundantSendable.swift`) to also strip `@unchecked Sendable` when (a) all stored fields are themselves `Sendable`, or (b) the only "unsafe" storage is `[any P.Type]` where `P: Sendable` (SE-0470 metatype). Today the rule handles redundant `: Sendable` on non-public structs/enums but not these `@unchecked` cases.

## Stage-1 / stage-2 rewrite candidates

- [ ] `Notification.Name` extension + matching `addObserver` / `post(name:userInfo:)` pair → `NotificationCenter.MainActorMessage` / `AsyncMessage` struct
- [ ] `NSAttributedString` / `NSMutableAttributedString` model storage → `AttributedString` (skip if used inside TextKit 2 layout pipeline)
- [ ] `Result<T, E>` return type whose body is `do { return .success(try …) } catch { return .failure(…) }` and whose only callers `switch` on the result → typed throws (`throws(E) -> T`)
- [ ] Chained `.map` / `.filter` / `.compactMap` / `.prefix` of length ≥3 on a collection only consumed by `.first(where:)` / a small prefix → insert `.lazy` at the head
- [ ] `swap(&a, &b); a.removeAll()` pattern recognition for alternating-buffer parsers — lint only (autofix unsafe)

## Excluded — already shipped

- XCTest → Swift Testing migration is fully covered by `PreferSwiftTesting` (`Sources/SwiftiomaticKit/Rules/Testing/PreferSwiftTesting.swift`): imports, assertions, `setUp`/`tearDown`, `@Test`, and bails on unsupported patterns. No child issues from §9.

## Out of scope (require deep flow / isolation analysis)

- Task.immediate silent executor-mismatch detection (needs full isolation graph)
- CoW Storage escape detection (needs alias analysis)
- Span/RawSpan refactor of `Data`/`Array` parameter chains

## Acceptance

Each child issue is "completed" when: rule lands behind a config flag, test cases for both positive and negative pass, and at least one real-world finding from the Swiftiomatic codebase itself is filed (or no false positives are observed in a `sm lint Sources/` run).



## Adjacent existing rules (extend, don't duplicate)

When implementing the candidates above, check these existing rules first — they may share helpers or warrant a shared base:

- `EmptyCollectionLiteral` — already handles literal-syntax cleanup; candidate #5 (`[]`/`[x]` argument substitution to `EmptyCollection()`/`CollectionOfOne(x)`) should likely live alongside it or extend it.
- `RetainNotificationObserver` — flags discarded observer tokens; candidate #8 (selector → closure migration) should coordinate with it.
- `PreferMainAttribute` — covers `@UIApplicationMain` migration; candidate #4 (`@MainActor` on `View`) is a different attribute but a sibling rule of similar shape.
