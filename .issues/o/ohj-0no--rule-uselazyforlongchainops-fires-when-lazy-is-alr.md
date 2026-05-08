---
# ohj-0no
title: rule [useLazyForLongChainOps] fires when '.lazy' is already present in multiline chain
status: completed
type: bug
priority: normal
created_at: 2026-05-08T02:02:06Z
updated_at: 2026-05-08T02:52:10Z
sync:
    github:
        issue_number: "648"
        synced_at: "2026-05-08T02:54:15Z"
---

## Symptom

The rule fires on chains that already include `.lazy`, when the chain is split across multiple lines.

```swift
let suffix = OrdinalTerm.suffixPreference(for: number)
    .lazy
    .compactMap { self[$0] }
    .filter { $0.matches(number) }
    .compactMap { $0.prefer(gender: gender) }
    .first
```

Diagnostic:
```
Integrations/CSL/Sources/Terms/Ordinals.swift:19:22: warning: [useLazyForLongChainOps] chain of 3 collection transforms allocates intermediate arrays — consider '.lazy'
```

Column 22 on line 19 points at the receiver (`OrdinalTerm`), not at any non-lazy chain. The chain operations downstream of `.lazy` should be skipped (lazy avoids intermediate allocations).

## Expected

When `.lazy` appears anywhere in the chain (or as the first call), subsequent operations should not be counted toward the threshold.

## Repro

Thesis project, `Integrations/CSL/Sources/Terms/Ordinals.swift:19`. Currently silenced with `// sm:ignore:next useLazyForLongChainOps`.


## Summary of Changes

- `Sources/SwiftiomaticKit/Rules/Idioms/UseLazyForLongChainOps.swift`: `chainLength` now resets the count to 0 when it encounters a `.lazy` member access in the receiver chain, then continues counting any eager chainable calls that appear *inside* `.lazy`'s base. `isChainLink` walks up through bridging member accesses (e.g. `.lazy`, `.map` calledExpression chains) so an inner call before `.lazy` isn't double-flagged as its own outermost chain.
- `Tests/SwiftiomaticTests/Rules/UseLazyForLongChainOpsTests.swift`: added `chainAlreadyLazyNotFlagged`, `multilineChainAlreadyLazyNotFlagged` (the issue repro), and `eagerCallsBeforeLazyStillCounted` (asserts pre-`.lazy` eager ops are still counted).
