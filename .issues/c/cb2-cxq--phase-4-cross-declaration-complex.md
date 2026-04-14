---
# cb2-cxq
title: 'Phase 4: Cross-declaration / complex'
status: ready
type: task
priority: normal
created_at: 2026-04-14T18:36:52Z
updated_at: 2026-04-14T18:36:52Z
parent: c7r-77o
sync:
    github:
        issue_number: "300"
        synced_at: "2026-04-14T18:45:53Z"
---

- [ ] `environmentEntry` — Use `@Entry` macro for EnvironmentValues. Requires recognizing `EnvironmentKey` struct + `EnvironmentValues` extension pattern spanning separate file-level declarations.
- [ ] `opaqueGenericParameters` — Use `some Protocol` instead of `<T: Protocol>`. Coordinated modification of generic params, where clauses, and parameter types. Must track usage across entire declaration. 200+ lines in SwiftFormat reference.
