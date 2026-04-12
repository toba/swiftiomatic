---
# m3e-xhk
title: 'Suggest rule: concurrency modernization additions (Task.immediate, SendableMetatype, nonisolated)'
status: ready
type: task
priority: normal
created_at: 2026-04-12T02:27:03Z
updated_at: 2026-04-12T02:27:03Z
parent: ogh-b3l
sync:
    github:
        issue_number: "207"
        synced_at: "2026-04-12T03:13:34Z"
---

## Overview

Add concurrency suggest patterns not covered by existing `ConcurrencyModernizationRule` or `Swift62ModernizationRule`.

## Patterns to detect

- [ ] `Task { }` in `@MainActor` context → `Task.immediate` (SE-0472) — body starts with MainActor work
- [ ] `@unchecked Sendable` on types only holding metatype arrays (`[any P.Type]`) → remove (SE-0470 SendableMetatype)
- [ ] `nonisolated(unsafe)` on values that are now Sendable in Swift 6.2+ (regex, enum, struct) → remove
- [ ] `Subprocess.run()` with default/empty `teardownSequence` → flag missing cleanup

## Notes

- Task.immediate is the highest value item — very common pattern
- Metatype check requires inspecting stored properties for `any P.Type` arrays
- `nonisolated(unsafe)` removal needs type analysis — may need SourceKit enrichment
- These could extend existing rules or be new rule files depending on complexity
