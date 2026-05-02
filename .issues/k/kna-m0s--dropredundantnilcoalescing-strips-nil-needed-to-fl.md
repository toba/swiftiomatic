---
# kna-m0s
title: DropRedundantNilCoalescing strips ?? nil needed to flatten double-optional from fetchOne
status: completed
type: bug
priority: normal
created_at: 2026-05-02T16:29:34Z
updated_at: 2026-05-02T16:32:30Z
sync:
    github:
        issue_number: "633"
        synced_at: "2026-05-02T17:32:31Z"
---

## Problem

`DropRedundantNilCoalescing` removes `?? nil` from expressions where it's actually required to flatten a double optional (`T??` → `T?`), producing code that fails to compile.

## Repro

Original (compiles):

```swift
let share = try await shadow.read { [recordName = record.recordName] db in
    try CloudRecord
        .where { $0.recordName.eq(recordName) }
        .select { $0.share }
        .fetchOne(db)
        ?? nil
}
guard let share else { ... }
try await unshare(share: share)
```

Here `fetchOne` returns `T?` where `T` is itself `Optional<CKShare>` (the `share` column is optional), so the raw result is `Optional<Optional<CKShare>>`. The `?? nil` flattens it to a single `Optional<CKShare>` so `guard let share` works.

After the rewrite (`?? nil` is stripped), the call to `unshare(share: share)` fails with:

> Value of optional type 'Optional<_SystemFieldsRepresentation<CKShare>>.QueryOutput' (aka 'Optional<CKShare>') must be unwrapped to a value of type 'CKShare'

because `share` is now still doubly-optional and `guard let` only peels one layer.

## Fix

`DropRedundantNilCoalescing` must not remove `?? nil` when the LHS type is itself optional (i.e., the expression is a double optional being flattened). The rule should only fire when the LHS is a single optional and the result is the same single optional — i.e., `?? nil` is genuinely a no-op.

Without full type info available to a syntactic rule, a safe heuristic: leave `?? nil` alone whenever the LHS could plausibly be double-optional. Conservative options:
- Skip when LHS is a chain ending in a method call whose receiver/argument types we can't see (e.g., `fetchOne`, `first`, `last`, dictionary subscript on optional values, `try?`).
- Or: require an explicit opt-in for this rule, since `?? nil` is rare and almost always intentional.

Prefer false negatives over false positives here — stripping `?? nil` breaks compilation.

## Tasks

- [x] Add a failing test reproducing the strip on a `fetchOne` (or analogous) call returning a double optional
- [x] Tighten `DropRedundantNilCoalescing` to skip cases where double-optional flattening is plausible
- [x] Confirm test passes; run full suite for regressions



## Summary of Changes

Added a syntactic guard to `DropRedundantNilCoalescing`: when the LHS of `?? nil` contains a function call, subscript, or `try?`, the rule now leaves the expression alone. These constructs may yield a doubly-optional value (`T??`), where `?? nil` is required to flatten to `T?`; without type info we can't distinguish, so we conservatively skip.

- `Sources/SwiftiomaticKit/Rules/Redundancies/DropRedundantNilCoalescing.swift`: added `lhsMayProduceDoubleOptional` helper that walks the LHS for `FunctionCallExprSyntax`, `SubscriptCallExprSyntax`, or `try?`.
- `Tests/SwiftiomaticTests/Rules/DropRedundantNilCoalescingTests.swift`: added 3 regression tests (`functionCallLHSNotFlagged`, `tryOptionalLHSNotFlagged`, `subscriptLHSNotFlagged`).

Full suite: 3196 passed.
