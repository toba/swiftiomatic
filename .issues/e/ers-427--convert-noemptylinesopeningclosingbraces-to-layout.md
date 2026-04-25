---
# ers-427
title: Convert NoEmptyLinesOpeningClosingBraces to layout
status: completed
type: task
priority: normal
created_at: 2026-04-24T23:55:24Z
updated_at: 2026-04-25T00:08:16Z
parent: os4-95x
sync:
    github:
        issue_number: "392"
        synced_at: "2026-04-25T01:59:57Z"
---

Remove blank lines after `{` and before `}` via maxBlankLines: 0 on the open/close breaks in `arrangeBracesAndContents`.

- [x] Add maxBlankLines: 0 via `arrangeNonEmptyBraces()` helper + `.same` break before `}`
- [x] Remove rewrite rule
- [x] Convert tests to layout tests (5 pass)
- [x] Regenerate and test (2531 pass)
