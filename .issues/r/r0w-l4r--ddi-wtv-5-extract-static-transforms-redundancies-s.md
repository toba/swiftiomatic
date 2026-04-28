---
# r0w-l4r
title: 'ddi-wtv-5: extract static transforms (Redundancies + Sort + Wrap + remaining)'
status: ready
type: task
priority: normal
created_at: 2026-04-28T02:42:46Z
updated_at: 2026-04-28T03:36:04Z
parent: ddi-wtv
blocked_by:
    - ogx-lb7
sync:
    github:
        issue_number: "494"
        synced_at: "2026-04-28T02:56:06Z"
---

Final mechanical refactor batch.

## Scope

- `Sources/SwiftiomaticKit/Rules/Redundancies/`
- `Sources/SwiftiomaticKit/Rules/Wrap/`
- `Sources/SwiftiomaticKit/Rules/LineBreaks/`
- `Sources/SwiftiomaticKit/Rules/Comments/`
- `Sources/SwiftiomaticKit/Rules/Testing/`
- Everything not covered by ddi-wtv-3 / ddi-wtv-4

Skip pure lint rules, threshold-only rules, and structural-pass rules.

## Done when

Every node-local rewrite rule exposes `static transform`; existing test suite green.
