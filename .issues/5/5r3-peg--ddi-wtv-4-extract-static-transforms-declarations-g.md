---
# 5r3-peg
title: 'ddi-wtv-4: extract static transforms (Declarations + Generics + Hoist + Idioms + Literals)'
status: ready
type: task
priority: normal
created_at: 2026-04-28T02:42:45Z
updated_at: 2026-04-28T02:42:45Z
parent: ddi-wtv
blocked_by:
    - ogx-lb7
sync:
    github:
        issue_number: "490"
        synced_at: "2026-04-28T02:56:06Z"
---

Continuation of the mechanical refactor. Same pattern as ddi-wtv-3.

## Scope

- `Sources/SwiftiomaticKit/Rules/Declarations/`
- `Sources/SwiftiomaticKit/Rules/Generics/`
- `Sources/SwiftiomaticKit/Rules/Hoist/`
- `Sources/SwiftiomaticKit/Rules/Idioms/`
- `Sources/SwiftiomaticKit/Rules/Literals/`

Skip pure lint rules and structural-pass rules.

## Done when

All in-scope rules expose `static transform`; existing test suite green.
