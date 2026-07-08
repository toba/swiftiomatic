---
# 7xy-lit
title: Three lint rules misfire on legitimate idioms (found vendoring xylem SAX parser)
status: completed
type: bug
priority: normal
created_at: 2026-07-08T03:06:09Z
updated_at: 2026-07-08T03:13:42Z
sync:
    github:
        issue_number: "752"
        synced_at: "2026-07-08T03:13:57Z"
---

While formatting/linting a vendored copy of the xylem XML SAX parser (Span-based, non-copyable, Swift 6.2 code), three rules produced findings on idiomatic, correct code. Two are error-level, so they block a clean `sm lint`. In each case the "fix" is impossible or changes semantics, so the only recourse is `sm:ignore`. Reasonable defaults should not flag these.

## 1. `noSwapThenRemoveAll` (error) — flags the very pattern it recommends
Repro:
```swift
struct DoubleBuffer<T> {
    var front: [T] = []
    private var back: [T] = []
    mutating func cycle(capacity: Int) {
        swap(&front, &back)                    // error: [noSwapThenRemoveAll]
        front.removeAll(keepingCapacity: true)
        front.reserveCapacity(capacity)
    }
}
```
The diagnostic says "consider an explicit double-buffer or reserveCapacity" — but this literally *is* an explicit double-buffer named `DoubleBuffer` doing the canonical front/back cycle with `keepingCapacity: true`. `swap` + `removeAll(keepingCapacity:)` is the standard allocation-reuse idiom, not a bug. Suggest: don't treat this as an error (downgrade to a lint-off/opt-in hint), or exempt when `keepingCapacity: true` is present (the "fragility" the rule warns about doesn't apply when capacity is deliberately retained).

## 2. `useContains` (warning) — conflates custom `first(_:)` with `first(where:) == nil`
Repro:
```swift
extension Span where Element == UInt8 {
    func first(_ element: Element) -> Index? { /* returns index of first match */ }
}
// ...
guard span.first(UInt8(ascii: ":")) == nil else { throw .invalidName }  // warning: [useContains]
```
The rule assumes `.first(...) == nil` is the `first(where:) { predicate } == nil` antipattern rewritable to `!contains(where:)`. Here `first(_ element:)` takes an **element** and returns an **Index**, and the receiver is a `Span` (not a `Sequence`), so `contains(where:)` does not exist and no rewrite is possible. Suggest: only match `first(where:)` with a **trailing-closure / closure argument**, not an arbitrary `first(_:)` call whose argument is a value, and skip receivers that don't offer `contains`.

## 3. `noUnusedSetterValue` (error) — flags intentional no-op default setters
Repro:
```swift
protocol Handler { var location: Location? { get set } }
extension Handler {
    var location: Location? {
        get { nil }
        set {}   // error: [noUnusedSetterValue]
    }
}
```
A default protocol-extension implementation that provides a **settable** requirement with a no-op default (so conformers opt in by overriding) is a legitimate, common pattern. The setter *must* exist to satisfy `{ get set }`; doing nothing is the point. Suggest: exempt empty setters (`set {}`) and/or setters in protocol-extension default implementations from this rule.

## Tasks
- [x] `noSwapThenRemoveAll`: don't error on the canonical double-buffer cycle (exempt `keepingCapacity: true`)
- [x] `useContains`: only fire on closure-form `first(where:)`, not value-arg `first(_:)`; require the receiver to actually offer `contains(where:)`
- [x] `noUnusedSetterValue`: exempt empty `set {}` and protocol-extension default setters

## Summary of Changes

- **`NoSwapThenRemoveAll`** (`Sources/SwiftiomaticKit/Rules/Idioms/NoSwapThenRemoveAll.swift`): `removeAllReceiverName` returns `nil` when the `removeAll` call carries `keepingCapacity: true`, so the canonical double-buffer cycle (`swap(&front, &back); front.removeAll(keepingCapacity: true)`) is no longer flagged. Deliberate capacity retention is the intended allocation-reuse idiom, not the fragile pattern the rule targets.
- **`UseContains`** (`Sources/SwiftiomaticKit/Rules/Collections/UseContains.swift`): pattern 3 (`first(where:) / firstIndex(where:) == nil`) now fires only for the closure form — a trailing closure or a `where:`-labeled argument. A custom value-arg `first(_:)` (e.g. `Span.first(byte)` returning an Index, receiver not a `Sequence`) is no longer misread as the rewritable antipattern.
- **`NoUnusedSetterValue`** (`Sources/SwiftiomaticKit/Rules/Declarations/NoUnusedSetterValue.swift`): the empty-body exemption no longer requires `override`; any empty `set {}` is now exempt, covering protocol-extension default setters that must supply a settable requirement for conformers to override. Removed the now-unused `isEnclosingDeclOverride` helper.

Added regression tests (`keepingCapacityTrueExempted`, `customFirstWithValueArgumentAccepted`, `emptyDefaultSetterInProtocolExtensionNotFlagged`, `emptyStandaloneSetterNotFlagged`); updated `swapThenRemoveAllOnFirstFlagged` to drop `keepingCapacity:`. Full suite green (3480 passed).

## Notes
Encountered in the Thesis project (Core/Sources/XML) vendoring github.com/thoven87/xylem @ 9881c95. All three were suppressed there with `// sm:ignore:next` + rationale.
