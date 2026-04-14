---
# xfy-in1
title: 'Phase 5: Scope analysis'
status: ready
type: task
priority: normal
created_at: 2026-04-14T18:37:00Z
updated_at: 2026-04-14T18:37:00Z
parent: c7r-77o
sync:
    github:
        issue_number: "303"
        synced_at: "2026-04-14T18:45:53Z"
---

- [ ] `redundantSelf` — Insert/remove explicit `self` (configurable). Requires scope analysis for variable shadowing and closure capture. Most complex rule in nicklockwood/SwiftFormat (~800 lines). Conservative subset (SE-0269 cases) is feasible first step. Parent: nnl-svw.
