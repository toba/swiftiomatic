---
# 6wc-ovo
title: Convert BlankLinesBetweenChainedFunctions to layout
status: completed
type: task
priority: normal
created_at: 2026-04-25T00:08:42Z
updated_at: 2026-04-25T00:13:49Z
parent: os4-95x
sync:
    github:
        issue_number: "393"
        synced_at: "2026-04-25T01:59:57Z"
---

Remove blank lines between chained function calls via maxBlankLines: 0 on the period breaks in member access chains.

- [x] Add maxBlankLines: 0 to contextual/same breaks before `.` in `insertContextualBreaks`
- [x] Remove rewrite rule
- [x] Convert tests to layout tests (3 pass)
- [x] Regenerate and test (2529 pass)



## Follow-up note

The remaining 7 blank line rules mostly INSERT blank lines (ensuring they exist), not remove them. The layout merge logic (.soft + .soft) uses the discretionary (trivia) count when merging, which overrides formatter-specified counts. A `minBlankLines` parameter or a different merge strategy would be needed to support insertion. These rules should stay as rewrite rules for now.
