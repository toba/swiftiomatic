---
# ogh-b3l
title: New suggestion rules from /swift skill gap analysis
status: ready
type: epic
priority: normal
created_at: 2026-04-11T23:47:28Z
updated_at: 2026-04-11T23:47:28Z
sync:
    github:
        issue_number: "200"
        synced_at: "2026-04-11T23:48:38Z"
---

## Overview

Comprehensive gap analysis comparing the `/swift` skill's analysis categories against the 320 existing Swiftiomatic rules. Since this tool targets **Swift 6.3+ / macOS 26+ only**, many modernization patterns are not just suggestions — they're the baseline expectation.

Existing rules already cover: `typed_throws`, `concurrency_modernization`, `swift62_modernization`, `observation_pitfalls`, `lock_anti_patterns`, `async_stream_safety`, `fire_and_forget_task`, `delegate_to_async_stream`, `prefer_weak_let`, `prefer_swift_testing`, `generic_consolidation`, `any_elimination`, `environment_entry`, `agent_review`, `date_for_timing`, `mutation_during_iteration`, `naming_heuristics`, `structural_duplication`, `swiftui_layout`, `redundant_view_builder`.

---

## High Value — Clear AST patterns, straightforward to implement

### Swift 6.3 Attribute Modernization (correctable lint rules)
- [ ] **`@_cdecl` → `@c`** — `@_cdecl` is replaced by `@c` in Swift 6.3. Simple attribute name match, auto-correctable. Also flag `@c("name")` syntax for custom C names.
- [ ] **`@_specialize` → `@specialize`** — No longer underscored. Simple attribute rename, auto-correctable. (`syntactic_sugar` has it in examples but doesn't check for it.)
- [ ] **`import struct`/`import class`/`import func` → `::`** — Module name selectors (`ModuleA::Type`) replace verbose selective imports. Suggest `::` syntax.

### SwiftUI Superseded Patterns (suggest rules)
- [ ] **`ObservableObject`/`@Published`/`@StateObject`/`@ObservedObject`/`@EnvironmentObject`** — All superseded by `@Observable` + `@State` + `@Environment`. Detect class conforming to `ObservableObject`, `@Published` properties, `@StateObject`/`@ObservedObject`/`@EnvironmentObject` wrappers. Very common in older code.
- [ ] **`NavigationView` → `NavigationSplitView`/`NavigationStack`** — Direct type reference detection.
- [ ] **`GeometryReader` → `Layout` protocol or `.visualEffect`** — Flag `GeometryReader` usage in SwiftUI views, suggest modern alternatives.
- [ ] **`@MainActor` on `View` conformance** — Redundant since SwiftUI views are implicitly `@MainActor`. Detect `@MainActor struct Foo: View` or `@MainActor` on View body. Could be a correctable lint rule.
- [ ] **`NSOpenPanel`/`NSSavePanel` → `.fileImporter`/`.fileExporter`** — Direct API reference detection. Flag in SwiftUI view files.
- [ ] **Formatters in SwiftUI body** — `DateFormatter()`, `NumberFormatter()`, `MeasurementFormatter()` allocated inside `body` or view computed properties. Causes re-creation every evaluation. Suggest caching as static/shared.
- [ ] **Sorting/filtering inside ForEach** — `.sorted(by:)`, `.filter { }` inside `ForEach` runs every body evaluation. Suggest precomputing.
- [ ] **Unstable ForEach identity** — `id: \.self` on non-`Identifiable`/mutable types. `UUID()` created per render.
- [ ] **Top-level if/else in View body** — Root-level conditional branches cause identity churn. Suggest stable root with conditional content inside.
- [ ] **`withAnimation` inside `onChange`** — When view has frequent non-animated state updates, last transaction wins. Suggest `.animation(_:value:)` scoped to animating view.

### Foundation Modernization (suggest rules)
- [ ] **`NSAttributedString`/`NSMutableAttributedString` → `AttributedString`** — Value type, Sendable, no bridging. Also flag `NSParagraphStyle`, `NSMutableParagraphStyle`, `enumerateAttributes(in:)`. Exception: TextKit 2 layout pipeline internals.
- [ ] **`Notification.Name` + `userInfo` → `NotificationCenter.Message`** (SE-0011) — Flag `Notification.Name` definitions, `post(name:object:userInfo:)` calls with userInfo dictionaries. Suggest typed `MainActorMessage`/`AsyncMessage` structs.
- [ ] **`Result<T, E>` return types → typed throws** — Functions returning `Result` that immediately switch/map can use typed throws instead. (Complements existing `typed_throws` which looks at throw statements.)

### Concurrency Modernization (suggest/lint rules)
- [ ] **`Task { }` in `@MainActor` → `Task.immediate`** (SE-0472) — Detect `Task { }` init inside `@MainActor` functions/closures where body does MainActor work first. Also flag debounce patterns (`task?.cancel(); task = Task { }`). Suggest `Task.immediate`.
- [ ] **`@unchecked Sendable` for metatype storage → remove** (SE-0470) — `@unchecked Sendable` on structs/classes holding `[any P.Type]` arrays where `P: Sendable`. Metatypes are now Sendable automatically.
- [ ] **`nonisolated(unsafe)` that's now safe** — Values that are Sendable in Swift 6.2+ (regex, enum, struct) no longer need `nonisolated(unsafe)`. Flag and suggest removal.
- [ ] **Subprocess without `teardownSequence`** — `Subprocess.run()` with default `PlatformOptions()` orphans child processes on cancellation. Flag when `teardownSequence` is empty/default.

### Testing Modernization (correctable lint rules)
- [ ] **XCTest assertion → Swift Testing assertion** — Individual XCT* calls: `XCTAssertEqual` → `#expect(==)`, `XCTAssertTrue` → `#expect()`, `XCTAssertNil` → `#expect(== nil)`, `XCTAssertThrowsError` → `#expect(throws:)`, `XCTUnwrap` → `try #require()`, etc. The existing `prefer_swift_testing` only flags `XCTestCase` classes — these would flag individual assertion calls even in mixed files. Could be a separate `prefer_swift_testing_assertions` rule.
- [ ] **`file: StaticString, line: UInt` → `sourceLocation: SourceLocation`** — Test helper source location parameter pattern. Detect the XCTest two-param pattern, suggest single `sourceLocation: SourceLocation = #_sourceLocation`.

---

## Medium Value — Detectable but need more context verification

### Performance (suggest rules)
- [ ] **Empty/single-element array to Collection param** — `[]` or `[x]` passed to `some Collection`/`some Sequence`/`any Collection`/`any Sequence` parameters. Heap allocates unnecessarily. Suggest `EmptyCollection()` / `CollectionOfOne(x)`. Don't flag when param type is explicitly `Array`/`[T]`.
- [ ] **Image decoding on main thread** — `UIImage(data:)` / `NSImage(data:)` inside SwiftUI `body`. Suggest offloading.
- [ ] **@Observable + onChange computed property** — `onChange(of:)` observing a computed property that derives from frequently-mutated state causes per-frame view re-evaluation.
- [ ] **`@TaskLocal` for business logic** — `@TaskLocal` used for required state (auth tokens, config) rather than cross-cutting concerns (logging, tracing). Silent bugs when forgotten via `withValue`.
- [ ] **Generic specialization in libraries** — Public generic functions in library targets without `@inlinable`. ~4x overhead per call from witness table dispatch.

### Collection Type Selection (suggest rules)
- [ ] **`Array.insert(at: 0)` / `removeFirst()` → `Deque`** — Hot-path FIFO operations on Array.
- [ ] **Array + `.contains()` → `OrderedSet`** — O(n) membership checks on Array.
- [ ] **Dictionary sorted by keys → `OrderedDictionary`** — `.sorted(by:)` on dictionary keys for display/serialization.
- [ ] **Sorted Array as priority queue → `Heap`** — `.sort()` after each `.append()`.
- [ ] **`Set<Int>` with dense ranges → `BitSet`** / **`[Bool]` → `BitArray`**

### SwiftUI Semantic (suggest rules)
- [ ] **Unnecessary ViewModels** — `@Observable` ViewModel that only holds state and forwards to services. Should use MV pattern (`@State` + `@Environment` + `.task`).
- [ ] **View member ordering** — Properties not following: `@Environment` → `let` → `@State` → computed → `init` → `body` → view builders → helpers.

---

## Lower Value — Need substantial semantic analysis

- [ ] **Parameter pack opportunities** — 3+ overloads differing only in generic arity → `<each T>`.
- [ ] **Sequence vs Collection over-constraining** — `Collection` constraint where only single-pass iteration is used.
- [ ] **Copy-on-write opportunities** — Large structs copied frequently but rarely mutated.
- [ ] **CKSyncEngine anti-patterns** — Very domain-specific (state persistence, fetchChanges in delegate, account changes).
- [ ] **Quadratic copy patterns** — `Data.dropFirst()` / `Data.prefix()` in loops.
- [ ] **Heap allocation for 0-1 element intermediate collections** — Chained `.flatMap`/`.map` creating intermediates.

---

## Implementation Notes

- Attribute rules (`@_cdecl`, `@_specialize`, `@MainActor` on View) are good candidates for **correctable lint rules** since they have unambiguous fixes
- SwiftUI superseded patterns (`ObservableObject`, `NavigationView`, `GeometryReader`) should be **suggest** scope since migration involves structural changes
- Foundation type replacements (`NSAttributedString`, `Notification.Name`) should be **suggest** scope
- `Task.immediate` should probably be **suggest** since not every Task in @MainActor context benefits
- Collection type suggestions should be **suggest** scope since they add a dependency
- Each bullet above could be its own rule file or grouped into thematic rules (e.g., one `swiftui_superseded_patterns` rule covering ObservableObject/NavigationView/GeometryReader/etc.)
