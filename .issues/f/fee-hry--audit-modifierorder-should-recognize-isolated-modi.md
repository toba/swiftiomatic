---
# fee-hry
title: 'Audit: ModifierOrder should recognize isolated modifier'
status: completed
type: bug
priority: normal
created_at: 2026-06-08T19:41:55Z
updated_at: 2026-06-08T19:52:42Z
sync:
    github:
        issue_number: "728"
        synced_at: "2026-06-08T19:59:33Z"
---

Upstream SwiftLint fix (realm/SwiftLint #6759 a43b0e7d, 2026-06-06) adds 'isolated' to modifier_order recognition.

Reference: ~/Developer/swiftiomatic-ref/SwiftLint/Source/SwiftLintBuiltInRules/Rules/Style/ModifierOrderRule.swift

Audit Swiftiomatic's ModifierOrder rule (apple/swift-format inherited) to ensure 'isolated' is in the recognized modifier list with correct ordering.



## Summary of Changes

Added `.isolated` to the canonical modifier order in `SortModifiers` so `isolated public func` is reordered to `public isolated func`, matching the isolation slot already occupied by `nonisolated`.

- Sources/SwiftiomaticKit/Rules/Declarations/SortModifiers.swift: `canonicalOrder` now contains `.isolated, .nonisolated` in the Isolation slot.
- Tests/SwiftiomaticTests/Rules/SortModifiersTests.swift: added `isolatedAfterAccessControl` (reorder case) and `isolatedAlreadyOrdered` (no-op case).

Verified via filtered `SortModifiersTests` run (11 passed).
