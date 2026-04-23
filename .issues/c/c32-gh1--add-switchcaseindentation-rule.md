---
# c32-gh1
title: Add SwitchCaseIndentation rule
status: completed
type: feature
priority: normal
created_at: 2026-04-18T04:16:19Z
updated_at: 2026-04-18T04:21:10Z
sync:
    github:
        issue_number: "347"
        synced_at: "2026-04-23T05:30:25Z"
---

- [x] Create SwitchCaseIndentation format rule in Indentation group
- [x] Create tests
- [x] Run generator
- [x] Build


## Summary of Changes

Added `SwitchCaseIndentation` format rule in the Indentation group. It dedents `case`/`default` labels to align with the `switch` keyword, and adjusts body indentation accordingly. Opt-in rule with 6 passing tests.
