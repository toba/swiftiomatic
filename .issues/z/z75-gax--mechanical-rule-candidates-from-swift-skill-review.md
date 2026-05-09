---
# z75-gax
title: Mechanical rule candidates from /swift skill review
status: completed
type: epic
priority: normal
created_at: 2026-05-09T15:56:08Z
updated_at: 2026-05-09T17:04:39Z
sync:
    github:
        issue_number: "676"
        synced_at: "2026-05-09T17:07:15Z"
---

Mechanical, AST-detectable rule candidates surfaced by reviewing `~/.claude/skills/swift/SKILL.md` against the existing rules under `Sources/SwiftiomaticKit/Rules/`. Each item below is a separate new rule; check off as implemented.

## Strong (mechanical, low FP)

- [x] **1. `FlagForEachOverIndices`** — flag `ForEach` whose receiver is integer-indexed (`<expr>.indices`, `a..<b` / `a...b`, `Range(...)`) **regardless of the `id:` argument** — the defect is the receiver shape (positional identity), not the id key path. Keep `FlagForEachIDSelfInView`'s existing `isIntegerIndexedReceiver` exemption so the two rules are orthogonal (id-axis vs receiver-axis) and can never co-fire on the same node. Reuse `isIntegerIndexedReceiver` verbatim. Flag-only v1; autofix to `ForEach(Array(<base>.enumerated()), id: \.element.id)` is a follow-up (needs base recovery for `0..<items.count` and assumes `Element: Identifiable`). Skill §"ForEach with index" (SKILL.md:1248-1261).
- [x] **2. `FlagSupersededSwiftUI`** (umbrella or per-attribute) — flag-only diagnostics for `@StateObject`, `@ObservedObject`, `@EnvironmentObject`, `@Published`, `ObservableObject` conformance, `NavigationView`. (Manual `EnvironmentKey` is already partly covered by `UseAtEntryNotEnvironmentKey`.) Table-driven, type/attribute name match. Skill §"Superseded Patterns".
- [x] **3. `NoAnyViewInForEach`** — flag `AnyView(...)` constructed inside a `ForEach` body. Skill §"SwiftUI Anti-patterns".
- [x] **4. `FlagMutableStaticVar`** — flag `static var` with mutable storage outside test files (`Tests/`, `*Tests.swift`). Fix is contextual (actor / `Mutex` / `@TaskLocal`), so flag-only. Skill §5.
- [x] **5. `FlagUncheckedSendable`** — review-only warning on `@unchecked Sendable`. Actual fix needs type info (e.g. SE-0470 metatype storage), so this just prompts review. Skill §5 SE-0470.
- [x] **6. `RequireSubprocessTeardownSequence`** — flag calls to `Subprocess.run(...)` lacking `platformOptions:` (or passing default `PlatformOptions()`). Skill §5 "Subprocess orphan processes".
- [x] **7. Audit `UseContinuousClockNotDate` coverage** — verify it catches `Date().timeIntervalSince(start)` and similar elapsed-timing patterns; extend if not.

## Borderline (flag-only, human verifies fix)

- [~] **8. `FlagNSAttributedStringMigration`** — scrapped (see Reasons for Scrapping). — flag `NSAttributedString`, `NSMutableAttributedString`, `NSParagraphStyle`, `NSMutableParagraphStyle`, `enumerateAttributes(in:)`, `addAttribute(_:value:range:)`. TextKit 2 internals are an exception — must honor `// sm:ignore`.
- [x] **9. `FlagTaskInMainActor`** — flag `Task { ... }` whose enclosing context is `@MainActor`-isolated; suggest `Task.immediate`. AST-detectable enclosing isolation; body-shape caveat (silent fallback if first work suspends off-main) handled in the message.
- [x] **10. `FlagTaskDetached`** — flag `Task.detached` calls; suggest `@concurrent` or `Task.immediateDetached`. Caveat: `@TaskLocal` inheritance behavior changes — note in message.
- [x] **11. `NoFirstIndexOfInForLoop`** — flag `for x in coll { ... coll.firstIndex(of: ...) ... }` where the `firstIndex` receiver matches the for-loop sequence (quadratic).

## Skipped (need type info or too semantic)

`Any`/`AnyObject`/`[String: Any]` elimination, `some Collection` vs `some Sequence`, `-able` vs `-ing` protocol naming, `[]`/`[x]` → `EmptyCollection()`/`CollectionOfOne(x)`, CoW opportunities, SIMD/SWAR scanning, `@TaskLocal` business vs cross-cutting, generic consolidation / parameter packs, `@inlinable` on public generics.



## Summary of Changes

- **9. `FlagTaskInMainActor`** — `Sources/SwiftiomaticKit/Rules/Unsafety/FlagTaskInMainActor.swift`. Walks enclosing parents looking for an explicit `@MainActor` attribute on any `WithAttributesSyntax` decl/closure; flags `Task(...)` calls (any priority arg form) under such a context. Anchored on the `Task` calledExpression. Tests: `Tests/SwiftiomaticTests/Rules/FlagTaskInMainActorTests.swift` (6 cases incl. negative coverage for `Task.detached` and `Task.immediate`).
- **10. `FlagTaskDetached`** — `Sources/SwiftiomaticKit/Rules/Unsafety/FlagTaskDetached.swift`. Member-call match on `Task.detached`; anchored on the `detached` declName so the diagnostic points at the method, not the receiver. Tests: 5 cases covering plain/priority forms, negative cases for `Task { }`, `Task.immediateDetached`, and unrelated `.detached` receivers.
- **11. `NoFirstIndexOfInForLoop`** — `Sources/SwiftiomaticKit/Rules/Idioms/NoFirstIndexOfInForLoop.swift`. Mirrors `NoDropFirstInForLoop`'s structure: extracts the leftmost identifier of the `for-in` sequence, walks the body skipping nested closures and loops, and flags `firstIndex(of:)` / `firstIndex(where:)` whose receiver's leftmost identifier matches. Anchored on the `firstIndex` token. Tests: 5 cases.

All three rules join the `unsafety` / `idioms` groups, are auto-registered by the build plugin, and pick up `LintPipeline` dispatch on next build. Full suite green: 3354 passed.

## Reasons for Scrapping

- **8. `FlagNSAttributedStringMigration`** — scrapped per user instruction. Note: the umbrella diagnostic over `NSAttributedString`, `NSMutableAttributedString`, `NSParagraphStyle`, `NSMutableParagraphStyle`, `enumerateAttributes(in:)`, `addAttribute(_:value:range:)` would generate too many false positives in code that legitimately interfaces with TextKit / Cocoa text APIs (composed attributed strings for `NSTextStorage`, `NSAttributedString.Key.attachment` for `NSTextAttachment`, etc.). A useful version would need scoped exemptions (TextKit subclassers, AppKit text view delegates) that are not mechanically detectable, leaving the rule mostly informational; coverage is better delivered via documentation than a noisy lint.
