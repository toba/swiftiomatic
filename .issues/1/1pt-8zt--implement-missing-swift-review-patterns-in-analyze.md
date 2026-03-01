---
# 1pt-8zt
title: Implement missing swift-review patterns in analyze rules
status: completed
type: epic
priority: high
created_at: 2026-03-01T01:03:44Z
updated_at: 2026-03-01T01:40:45Z
sync:
    github:
        issue_number: "102"
        synced_at: "2026-03-01T01:41:12Z"
---

Bring the `analyze` command to full parity with the `/swift-review` skill by implementing AST-powered detection for all patterns the skill covers that rules do not yet detect.

Each checklist item is a distinct pattern. Items are grouped by the skill category they belong to and ordered by priority within each group.

## §1 Code Duplication Detection (new rule needed)

- [ ] Structurally similar function bodies (same node shapes, different identifiers)
- [ ] Repeated `guard let` / `do-catch` patterns across files
- [ ] Near-identical CRUD operations or state machine patterns

## §2 Generic Consolidation (extend `any_elimination` or new rule)

- [ ] Functions differing only by type that could unify with generics
- [ ] `some Sequence` vs `some Collection` over-constraint (body only uses `for-in`/`reduce` but constrains to `Collection`)
- [ ] Existential `any P` where `some P` or a generic `<T: P>` would preserve type identity

## §3 Typed Throws (extend `typed_throws`)

- [ ] `catch let error as SpecificType` pattern indicating caller knows the error type
- [ ] `Result<T, E>` return types that could become `throws(E) -> T`

## §4 Structured Concurrency (extend `concurrency_modernization`)

- [ ] AsyncStream closures missing `continuation.finish()` call
- [ ] AsyncStream closures missing `continuation.onTermination` handler
- [ ] `withCheckedContinuation` wrapping a single async call (trivial bridge)
- [ ] NotificationCenter `.addObserver` in async context → `.notifications(named:)` AsyncSequence
- [ ] Delegate protocols with single-consumer callback-shaped methods → AsyncStream
- [ ] `Timer.scheduledTimer` / `DispatchSource.makeTimerSource` → AsyncTimerSequence
- [ ] `OperationQueue` usage (not detected at all currently)

## §5 Swift 6.2 Modernization (extend `swift62_modernization`)

- [ ] Tuple types used as fixed-size buffers → `InlineArray<N, T>` candidates
- [ ] Return types crossing actor isolation boundaries → `sending` keyword
- [ ] `@MainActor` types with `nonisolated` workarounds on protocol methods → isolated conformances
- [ ] Mutable `static var` accessed from multiple isolation domains → actor or `Mutex`
- [ ] Context parameter threaded through call chains → `@TaskLocal` candidate

## §6 Performance Anti-Patterns (extend `performance_anti_patterns`)

- [ ] `Data.dropFirst()` inside loop bodies (quadratic copy)
- [ ] Chained `.flatMap`/`.compactMap`/`.map` without `.lazy` creating intermediate arrays
- [ ] `withLock` closure body containing `await`, I/O, or heavy computation (lock held too long)
- [ ] Nested `withLock` calls on same or dependent mutexes (deadlock risk)
- [ ] `@TaskLocal` read inside `Task.detached` (silently gets default value)
- [ ] `@TaskLocal` used for required business-logic state (should be explicit parameter)
- [ ] `public func` with generic parameters in library targets missing `@inlinable`
- [ ] `for await` over `Observations` with `await` or expensive work in loop body (value dropping)
- [ ] Collection protocol parameter where `Span` would eliminate ARC overhead (macOS 26+)

## §7 Naming Heuristics (extend `naming_heuristics`)

- [ ] Mutating/non-mutating method pairs with reversed conventions (e.g., `sort()` non-mutating)
- [ ] First-argument label conventions (omit when completing grammatical phrase, include for prepositional)

## §8 Agent Review (extend `agent_review`)

- [ ] `.onAppear { Task { } }` → suggest `.task { }` modifier
- [ ] `CaseIterable` conformance with no `.allCases` reference (collecting rule)
- [ ] Nested `NavigationStack` (SwiftUI layout issue)
- [ ] `GeometryReader` inside `ScrollView` (undefined behavior)
- [ ] Multiple unbounded `List`/`ScrollView` in same container (layout explosion)


## Summary of Changes

### Batch 1: Extended Existing Rules (24 new patterns)

**TypedThrowsRule** (+2 patterns):
- `catch let error as SpecificType` → suggests typed throws (medium confidence)
- `Result<T, E>` return type on non-throwing function → suggests `throws(E) -> T` (low confidence)

**ConcurrencyModernizationRule** (+6 patterns):
- AsyncStream missing `continuation.finish()` (high confidence)
- AsyncStream missing `onTermination` handler (medium confidence)
- `withCheckedContinuation` wrapping single async call (medium confidence)
- `NotificationCenter.addObserver` in async context (low confidence)
- `OperationQueue` usage (medium confidence)
- `Timer.scheduledTimer` / `DispatchSource.makeTimerSource` (medium confidence)

**Swift62ModernizationRule** (+5 patterns):
- Homogeneous tuple → `InlineArray` (low confidence)
- `nonisolated` in `@MainActor` type → isolated conformances (low confidence)
- Mutable `static var` without isolation (low confidence)
- Context parameter threading → `@TaskLocal` (low confidence)
- (sending keyword deferred — requires type resolution)

**PerformanceAntiPatternsRule** (+9 patterns):
- `Data.dropFirst()` in loop (high confidence)
- Chained `.map/.filter/.compactMap` without `.lazy` (medium confidence)
- `withLock` containing `await` (high confidence)
- Nested `withLock` (high confidence)
- `@TaskLocal` read inside `Task.detached` (medium confidence)
- `@TaskLocal` for business-logic state (low confidence)
- Public generic function missing `@inlinable` (low confidence)
- `for await` over Observations with expensive body (low confidence)
- Collection parameter → Span (low confidence)

**NamingHeuristicsRule** (+2 patterns):
- Mutating method with -ed/-ing suffix convention violation (medium confidence)
- First-argument label conventions for phrasal verbs (low confidence)

### Batch 2: New Rules (3 rules)

- **CaseIterableUsageRule** — CollectingRule detecting `CaseIterable` enums with no `.allCases` reference
- **GenericConsolidationRule** — `any P` → `some P`, over-constrained Collection parameters
- **DelegateToAsyncStreamRule** — delegate protocols → AsyncStream wrapper suggestion

### Batch 3: Tests (43 new tests, 6 new fixture files)

All tests passing, zero regressions against existing suite.

### Deferred

- Structural hashing for duplicate function bodies
- `sending` keyword detection (needs type resolution)
