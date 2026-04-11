---
# 04e-hge
title: '`redundant_sendable`: detect redundant conformance in public extension context'
status: completed
type: bug
priority: normal
created_at: 2026-04-11T17:53:01Z
updated_at: 2026-04-11T18:19:01Z
sync:
    github:
        issue_number: "177"
        synced_at: "2026-04-11T18:44:01Z"
---

The `redundant_sendable` rule currently only checks types decorated with `@MainActor` or configured global actors. It does not detect redundant `Sendable` conformance on types defined inside public extensions that inherit isolation.

Upstream reference: nicklockwood/SwiftFormat 0.60.1 fixed `redundantSendable` incorrectly removing `Sendable` conformance on types in public extensions.


## Summary of Changes

Updated `isIsolatedToActor()` in `RedundantSendableRule` to walk ancestor declarations. Types inside a `@MainActor` extension or nested inside a `@MainActor` parent type now correctly inherit that isolation, making their explicit `Sendable` conformance flaggable as redundant.

**Changed file:** `Sources/SwiftiomaticKit/Rules/Redundancy/Visibility/RedundantSendableRule.swift`

- Extracted attribute check into `AttributeListSyntax.isActorIsolated(actors:)` helper
- `isIsolatedToActor()` now walks the parent syntax chain checking all `DeclGroupSyntax` ancestors (extensions, structs, classes, enums) for global actor attributes
- Added non-triggering examples: types in plain extensions and public extensions (no isolation)
- Added triggering examples: type in `@MainActor extension`, nested type in `@MainActor struct`
- Added correction pairs for both new triggering cases
