---
# ogh-b3l
title: New suggestion rules from /swift skill gap analysis
status: in-progress
type: epic
priority: normal
created_at: 2026-04-11T23:47:28Z
updated_at: 2026-04-13T00:11:27Z
sync:
    github:
        issue_number: "200"
        synced_at: "2026-04-13T00:25:19Z"
---

## Overview

Comprehensive gap analysis comparing the `/swift` skill's analysis categories against the 320 existing Swiftiomatic rules. Since this tool targets **Swift 6.3+ / macOS 26+ only**, many modernization patterns are not just suggestions — they're the baseline expectation.

Existing rules already cover: `typed_throws`, `concurrency_modernization`, `swift62_modernization`, `observation_pitfalls`, `lock_anti_patterns`, `async_stream_safety`, `fire_and_forget_task`, `delegate_to_async_stream`, `prefer_weak_let`, `prefer_swift_testing`, `generic_consolidation`, `any_elimination`, `environment_entry`, `agent_review`, `date_for_timing`, `mutation_during_iteration`, `naming_heuristics`, `structural_duplication`, `swiftui_layout`, `redundant_view_builder`.

---

## High Value — Clear AST patterns, straightforward to implement

### Swift 6.3 Attribute Modernization (correctable lint rules)
- [x] **`@_cdecl` → `@c`** — `@_cdecl` is replaced by `@c` in Swift 6.3. Simple attribute name match, auto-correctable. Also flag `@c("name")` syntax for custom C names.
- [x] **`@_specialize` → `@specialize`** — No longer underscored. Simple attribute rename, auto-correctable. (`syntactic_sugar` has it in examples but doesn't check for it.)
- [x] **`import struct`/`import class`/`import func` → `::`** — Module name selectors (`ModuleA::Type`) replace verbose selective imports. Suggest `::` syntax.

### SwiftUI Superseded Patterns (suggest rules)
- [x] **`ObservableObject`/`@Published`/`@StateObject`/`@ObservedObject`/`@EnvironmentObject`** — All superseded by `@Observable` + `@State` + `@Environment`. Detect class conforming to `ObservableObject`, `@Published` properties, `@StateObject`/`@ObservedObject`/`@EnvironmentObject` wrappers. Very common in older code.
- [x] **`NavigationView` → `NavigationSplitView`/`NavigationStack`** — Direct type reference detection.
- [x] **`GeometryReader` → `Layout` protocol or `.visualEffect`** — Flag `GeometryReader` usage in SwiftUI views, suggest modern alternatives.
- [x] **`@MainActor` on `View` conformance** — Redundant since SwiftUI views are implicitly `@MainActor`. Detect `@MainActor struct Foo: View` or `@MainActor` on View body. Could be a correctable lint rule.
- [x] **`NSOpenPanel`/`NSSavePanel` → `.fileImporter`/`.fileExporter`** — Direct API reference detection. Flag in SwiftUI view files.
- [x] **Formatters in SwiftUI body** — `DateFormatter()`, `NumberFormatter()`, `MeasurementFormatter()` allocated inside `body` or view computed properties. Causes re-creation every evaluation. Suggest caching as static/shared.
- [x] **Sorting/filtering inside ForEach** — `.sorted(by:)`, `.filter { }` inside `ForEach` runs every body evaluation. Suggest precomputing.
- [x] **Unstable ForEach identity** — `id: \.self` on non-`Identifiable`/mutable types. `UUID()` created per render.
- [x] **Top-level if/else in View body** — Root-level conditional branches cause identity churn. Suggest stable root with conditional content inside.
- [x] **`withAnimation` inside `onChange`** — When view has frequent non-animated state updates, last transaction wins. Suggest `.animation(_:value:)` scoped to animating view.

### Foundation Modernization (suggest rules)
- [x] **`NSAttributedString`/`NSMutableAttributedString` → `AttributedString`** — Value type, Sendable, no bridging. Also flag `NSParagraphStyle`, `NSMutableParagraphStyle`, `enumerateAttributes(in:)`. Exception: TextKit 2 layout pipeline internals.
- [x] **`Notification.Name` + `userInfo` → `NotificationCenter.Message`** (SE-0011) — Flag `Notification.Name` definitions, `post(name:object:userInfo:)` calls with userInfo dictionaries. Suggest typed `MainActorMessage`/`AsyncMessage` structs.
- [x] **`Result<T, E>` return types → typed throws** — Functions returning `Result` that immediately switch/map can use typed throws instead. (Complements existing `typed_throws` which looks at throw statements.)

### Concurrency Modernization (suggest/lint rules)
- [x] **`Task { }` in `@MainActor` → `Task.immediate`** (SE-0472) — Detect `Task { }` init inside `@MainActor` functions/closures where body does MainActor work first. Also flag debounce patterns (`task?.cancel(); task = Task { }`). Suggest `Task.immediate`.
- [x] **`@unchecked Sendable` for metatype storage → remove** (SE-0470) — `@unchecked Sendable` on structs/classes holding `[any P.Type]` arrays where `P: Sendable`. Metatypes are now Sendable automatically.
- [x] **`nonisolated(unsafe)` that's now safe** — Values that are Sendable in Swift 6.2+ (regex, enum, struct) no longer need `nonisolated(unsafe)`. Flag and suggest removal.
- [x] **Subprocess without `teardownSequence`** — `Subprocess.run()` with default `PlatformOptions()` orphans child processes on cancellation. Flag when `teardownSequence` is empty/default.

### Testing Modernization (correctable lint rules)
- [x] **XCTest assertion → Swift Testing assertion** — Individual XCT* calls: `XCTAssertEqual` → `#expect(==)`, `XCTAssertTrue` → `#expect()`, `XCTAssertNil` → `#expect(== nil)`, `XCTAssertThrowsError` → `#expect(throws:)`, `XCTUnwrap` → `try #require()`, etc. The existing `prefer_swift_testing` only flags `XCTestCase` classes — these would flag individual assertion calls even in mixed files. Could be a separate `prefer_swift_testing_assertions` rule.
- [x] **`file: StaticString, line: UInt` → `sourceLocation: SourceLocation`** — Test helper source location parameter pattern. Detect the XCTest two-param pattern, suggest single `sourceLocation: SourceLocation = #_sourceLocation`.

---

## Medium Value — Mechanical Detection

These items have clear AST patterns detectable without SourceKit type resolution.

### Collection Type Selection (new grouped suggest rule: `collection_type_selection`)
- [x] **`Array.insert(at: 0)` / `removeFirst()` → `Deque`** — Match `FunctionCallExprSyntax` for `.insert` with literal `0` arg, and `.removeFirst()` calls. Strong syntactic signal.
- [x] **`if !x.contains(y) { x.append(y) }` → `OrderedSet`** — Match if-not-contains-then-append on same receiver in `IfExprSyntax` + `CodeBlockSyntax`.
- [x] **`.sort()` after `.append()` → `Heap`** — Sequential statements on same receiver in a `CodeBlockItemListSyntax`.

### SwiftUI View Member Ordering (new suggest rule: `swiftui_view_member_ordering`)
- [x] **View member ordering** — Classify members by attribute (`@Environment`, `@FocusState`, `@State`) and kind (`let`, `init`, `body`, func). Existing `type_contents_order` only knows UIKit lifecycle categories — has no SwiftUI-specific attribute awareness. Expected order: `@Environment`/`@FocusState` → `let` → `@State` → computed var → `init` → `body` → view builders → helpers.

### SwiftUI View Anti-Patterns (extend existing `swiftui_view_anti_patterns`)
- [x] **Image decoding in body** — `NSImage(data:)` / `UIImage(data:)` inside SwiftUI `body`. Same `bodyDepth` tracking pattern as existing formatter-in-body check.

---

## Medium Value — Heuristic Detection (not pursuing)

Reviewed 2026-04-12. None of these are feasible with acceptable signal-to-noise ratio. SourceKit provides `resolveType` (cursorinfo), `expressionTypes` (all expression types), and `indexFile` (USR-based declarations/references) — but cannot determine protocol conformance, type hierarchies, or semantic property dependency chains. The `AsyncEnrichableRule` infrastructure (4 existing conformers) is proven, so the blocker is SourceKit's depth, not our pipeline.

The oad-n72 swift-syntax tooling (FixItApplier, diagnostic highlights/notes, DiagnosticCategory, incremental parsing, SwiftSyntaxBuilder, AST-level FixIt.Change) improves output and corrections but does not enable new detection capabilities.

### Needs SourceKit type resolution
- [x] ~~**Empty/single-element array to Collection param**~~ — **Not pursuing.** Would need function parameter type info (is it `some Collection` vs `[T]`?). `resolveType` gives function type but parsing param types from type strings is fragile. Even with resolution, `[]` passed to `[T]` is completely normal — false positive rate too high.
- [x] ~~**Dictionary sorted by keys → `OrderedDictionary`**~~ — **Not pursuing.** `.sorted(by:)` on Dictionary is a normal, correct operation yielding `[(key: K, value: V)]`. `OrderedDictionary` only helps when maintaining sorted order across mutations — a usage context we can't determine from a single call site.
- [x] ~~**`Set<Int>` with dense ranges → `BitSet`** / **`[Bool]` → `BitArray`**~~ — **Not pursuing.** Type annotations are syntactically visible but collection size is a runtime property. A 5-element `[Bool]` for flags is fine; a 10,000-element one for a sieve should be `BitArray`. We can't distinguish without runtime profiling.

### Needs semantic understanding
- [x] ~~**@Observable + onChange computed property**~~ — **Not pursuing.** Tracing property dependency chains (computed → stored → mutation frequency) is beyond SourceKit's capabilities entirely.
- [x] ~~**`@TaskLocal` for business logic**~~ — **Not pursuing.** Distinguishing cross-cutting concerns from business logic is a human semantic judgment with no syntactic or type-level signal.
- [x] ~~**Unnecessary ViewModels**~~ — **Not pursuing.** Determining whether a class "adds real logic" vs "just forwards" requires understanding method semantics. Too opinionated for a linter.

### Already covered by existing rules
- [x] **Generic specialization in libraries** — Covered by `inlinable_generic` rule.

---

## Lower Value — Need substantial semantic analysis (deferred)

- [ ] **Parameter pack opportunities** — 3+ overloads differing only in generic arity → `<each T>`. Needs logic similarity analysis across overloads.
- [ ] **Sequence vs Collection over-constraining** — `Collection` constraint where only single-pass iteration is used. Needs function body analysis.
- [ ] **Copy-on-write opportunities** — Large structs copied frequently but rarely mutated. Needs size/frequency analysis.
- [ ] **CKSyncEngine anti-patterns** — Very domain-specific (state persistence, fetchChanges in delegate, account changes). Mixed mechanical/semantic.
- [x] **Quadratic copy patterns** — `Data.dropFirst()` / `Data.prefix()` in loops. Already covered by `mutation_during_iteration`.
- [ ] **Heap allocation for 0-1 element intermediate collections** — Chained `.flatMap`/`.map` creating intermediates. Needs hot-path context.

---

## Implementation Notes

- Attribute rules (`@_cdecl`, `@_specialize`, `@MainActor` on View) are good candidates for **correctable lint rules** since they have unambiguous fixes
- SwiftUI superseded patterns (`ObservableObject`, `NavigationView`, `GeometryReader`) should be **suggest** scope since migration involves structural changes
- Foundation type replacements (`NSAttributedString`, `Notification.Name`) should be **suggest** scope
- `Task.immediate` should probably be **suggest** since not every Task in @MainActor context benefits
- Collection type suggestions should be **suggest** scope since they add a dependency
- Each bullet above could be its own rule file or grouped into thematic rules (e.g., one `swiftui_superseded_patterns` rule covering ObservableObject/NavigationView/GeometryReader/etc.)


## Implementation Priority

1. **`collection_type_selection`** (new grouped suggest rule) — `.insert(at: 0)`/`.removeFirst()` → Deque, `if !contains then append` → OrderedSet, `.sort()` after `.append()` → Heap
2. **`swiftui_view_member_ordering`** (new suggest rule) — @Environment → let → @State → computed → init → body → view builders → helpers
3. **Image decoding in body** (extend `swiftui_view_anti_patterns`) — NSImage(data:)/UIImage(data:) inside body
