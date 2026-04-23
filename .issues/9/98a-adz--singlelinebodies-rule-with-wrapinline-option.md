---
# 98a-adz
title: SingleLineBodies rule with wrap/inline option
status: completed
type: feature
priority: normal
created_at: 2026-04-18T04:03:31Z
updated_at: 2026-04-18T04:10:30Z
sync:
    github:
        issue_number: "343"
        synced_at: "2026-04-23T05:30:25Z"
---

- [x] Rename WrapBodies → SingleLineBodies
- [x] Add SingleLineBodiesConfiguration with mode enum (wrap/inline)
- [x] Implement inline mode: collapse multi-line single-statement bodies if they fit within lineLength
- [x] Keep existing wrap mode behavior
- [x] Update tests
- [x] Run generate-swiftiomatic
- [x] Build and verify


## Summary of Changes

Renamed `WrapBodies` → `SingleLineBodies` with a `SingleLineBodiesConfiguration` that has a `mode` enum (`wrap`/`inline`). Wrap mode preserves existing behavior. Inline mode collapses multi-line single-statement bodies onto one line if they fit within `lineLength`. 70 tests pass (50 wrap + 20 inline).
