---
# jar-zbs
title: Add per-break maxBlankLines to layout system
status: completed
type: task
priority: normal
created_at: 2026-04-24T23:38:33Z
updated_at: 2026-04-24T23:54:13Z
parent: os4-95x
sync:
    github:
        issue_number: "394"
        synced_at: "2026-04-25T01:59:57Z"
---

Add a `maxBlankLines` parameter to break tokens so the layout coordinator can enforce per-context blank line limits. This unblocks converting the 10 blank line rewrite rules.

- [x] Add `maxBlankLines: Int?` parameter to `NewlineBehavior.soft`
- [x] Thread through `LayoutCoordinator` pattern matches
- [x] `LayoutBuffer.writeNewlines()` uses per-break `maxBlankLines` when set
- [x] 2532 tests pass, 0 failures
- [x] BlankLinesBetweenImports converted as proof of concept
