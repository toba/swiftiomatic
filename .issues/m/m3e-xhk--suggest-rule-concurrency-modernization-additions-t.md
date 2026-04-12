---
# m3e-xhk
title: 'Suggest rule: concurrency modernization additions (Task.immediate, SendableMetatype, nonisolated)'
status: completed
type: task
priority: normal
created_at: 2026-04-12T02:27:03Z
updated_at: 2026-04-12T23:11:13Z
parent: ogh-b3l
sync:
    github:
        issue_number: "207"
        synced_at: "2026-04-12T23:20:53Z"
---

## Overview

Add concurrency suggest patterns not covered by existing `ConcurrencyModernizationRule` or `Swift62ModernizationRule`.

## Patterns to detect

- [x] `Task { }` in `@MainActor` context → `Task.immediate` (SE-0472) — body starts with MainActor work
- [x] `@unchecked Sendable` on types only holding metatype arrays (`[any P.Type]`) → remove (SE-0470 SendableMetatype)
- [x] `nonisolated(unsafe)` on values that are now Sendable in Swift 6.2+ (regex, enum, struct) → remove
- [x] `Subprocess.run()` with default/empty `teardownSequence` → flag missing cleanup

## Notes

- Task.immediate is the highest value item — very common pattern
- Metatype check requires inspecting stored properties for `any P.Type` arrays
- `nonisolated(unsafe)` removal needs type analysis — may need SourceKit enrichment
- These could extend existing rules or be new rule files depending on complexity


## Summary of Changes

All 4 patterns added to `SwiftModernizationRule` (renamed from `Swift62ModernizationRule`):
- Task.immediate detection in @MainActor context
- nonisolated(unsafe) on Sendable values (regex, enum)
- @unchecked Sendable on structs with metatype storage (SE-0470)
- Subprocess.run without platformOptions/teardownSequence
