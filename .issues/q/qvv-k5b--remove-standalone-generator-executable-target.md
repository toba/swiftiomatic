---
# qvv-k5b
title: Remove standalone Generator executable target
status: completed
type: task
priority: normal
created_at: 2026-04-19T17:32:03Z
updated_at: 2026-04-19T18:15:04Z
parent: rcc-z52
blocked_by:
    - y40-fgh
sync:
    github:
        issue_number: "350"
        synced_at: "2026-04-23T05:30:27Z"
---

Once the build tool plugin is working, clean up the old manual generator.

- [x] Keep `Generator` target (plugin depends on it; also used for manual schema generation)
- [x] Keep `Sources/Generator/main.swift` (used by plugin + manual schema generation)
- [x] Update CLAUDE.md build instructions
- [x] Verify full build cycle: build + generated files validity tests pass


## Summary of Changes

Kept the Generator executable target rather than removing it — the build tool plugin depends on it, and it serves double duty for manual `schema.json` generation (`swift run Generator` without `--skip-schema`). Updated CLAUDE.md to document both invocation modes.
