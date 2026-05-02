---
# 7l3-lzx
title: dropRedundantNilCoalescing flags wrong location (doc comment / struct decl)
status: completed
type: bug
priority: normal
created_at: 2026-05-02T16:24:00Z
updated_at: 2026-05-02T16:34:45Z
sync:
    github:
        issue_number: "632"
        synced_at: "2026-05-02T17:32:31Z"
---

Xcode shows `[dropRedundantNilCoalescing] remove redundant...` warnings attached to lines 7 and 8 of a file where there is no nil-coalescing operator anywhere near those lines.

## Repro

```swift
import GRDB
import SwiftUI
public import CloudKit

/// A shared record that can be used to present a ``CloudSharingView``.
///
/// See <doc:CloudKitSharing#Creating-CKShare-records> for more information.
public struct SharedRecord: Hashable, Identifiable, Sendable {
    let container: any CloudContainer
    public let share: CKShare

    public var id: CKRecord.ID { share.recordID }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.container == rhs.container && lhs.share == rhs.share
    }
}
```

Lint warnings appear on:
- Line 7 (doc comment line `/// See <doc:...> for more information.`)
- Line 8 (`public struct SharedRecord: Hashable, Identifiable, Sendable {`)

Neither line contains `??`. The finding location is wrong, or the rule is matching something it shouldn't (possibly the `<doc:...>` angle brackets in the doc comment, or some token in the inheritance clause).

## Expected

No `dropRedundantNilCoalescing` finding on this file. The rule should only fire on actual `??` operators with a provably non-optional LHS.

## Investigation

- Check `Sources/SwiftiomaticKit/Rules/Redundancies/DropRedundantNilCoalescing.swift` for over-broad pattern matching
- Verify the rule visits only `InfixOperatorExprSyntax` with operator `??`
- Confirm the finding location is anchored to the actual `??` token, not the enclosing decl

## Tasks

- [x] Add a test reproducing the false positive on the snippet above
- [x] Fix the rule to not fire on this input
- [x] Confirm filtered test suite passes



## Summary of Changes

**Root cause:** `DropRedundantNilCoalescing.transform` emitted findings via `Self.diagnose(..., on: op.operator, ...)` where `op` was derived from `node` — the *post-children-rewrite* `InfixOperatorExprSyntax`. When other rules (e.g. `DropRedundantSelf`, `SplitMultipleDeclsPerLine`) rewrote subtrees during the same `CompactSyntaxRewriter` walk, the rebuilt subtree containing the `??` token was detached from the source-file root. `SourceLocationConverter` is built once from the *original* source bytes, so `startLocation(converter:)` on the detached operator token mapped its intra-subtree offset (small) back to an early line in the original file — producing warnings anchored to lines 7-8 instead of 122/146/219.

**Fix:** Anchor the diagnostic on `original.operator` (the pre-rewrite input passed alongside `node` to the static transform), which is still attached to the original source-file root and reports the correct line/column.

**Files changed:**
- `Sources/SwiftiomaticKit/Rules/Redundancies/DropRedundantNilCoalescing.swift` — use `original` for finding anchor; added explanatory comment.
- `Tests/SwiftiomaticTests/Rules/DropRedundantNilCoalescingTests.swift` — added `findingLocationOnLaterLine` regression test.

Verified by running the rebuilt `sm lint` against `Core/Sources/CloudKit/Sync/CloudKitSharing.swift` from the thesis project — the previously-bogus warnings on lines 7 and 8 are gone.
