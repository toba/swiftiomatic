---
# xah-el5
title: 'Dead code: commented ConfigurationItem, missing schemaURL ref'
status: completed
type: task
priority: low
created_at: 2026-04-25T20:43:43Z
updated_at: 2026-04-25T22:11:43Z
parent: 0ra-lks
sync:
    github:
        issue_number: "420"
        synced_at: "2026-04-25T22:35:10Z"
---

## Findings

- [x] Deleted `Sources/ConfigurationKit/ConfigurationItem.swift` — enum was unreferenced anywhere in the codebase
- [x] Moved `Configuration.schemaURL` from `Configuration+Dump.swift` to `Configuration.swift` (next to its `encode(to:)` use site)
- [x] Reviewed single-reference helpers:
  - `PreferSynthesizedInitializer.swift:34` is `contains(anyOf:)` — that's the shared helper extracted in c0v-u8y, not a single-reference; no change.
  - `WrapMultilineFunctionChains.isTypeAccess(after:)` is called twice (lines 45 and 58); the named predicate aids readability over inlining the `nextToken/identifier/uppercase` chain twice. Kept.
  - Other private helpers (`matchesAccessLevel`, `matchesPropertyList`, `matchesAssignmentBody` in PreferSynthesizedInitializer) similarly express named domain checks. Kept.

## Test plan
- [x] Build still passes after deletions


## Summary of Changes

- Deleted `Sources/ConfigurationKit/ConfigurationItem.swift` (no callers anywhere; everything inside was either an unused enum or commented-out code).
- Moved `Configuration.schemaURL` from `Configuration+Dump.swift` to `Configuration.swift` so it sits next to its only producer (`encode(to:)`'s `$schema` write).
- Reviewed flagged single-reference helpers; none warrant inlining (they encode named domain predicates).
