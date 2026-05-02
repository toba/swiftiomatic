---
# rua-efw
title: else-if condition wrapped to brace-on-next-line
status: completed
type: bug
priority: normal
created_at: 2026-05-01T23:24:57Z
updated_at: 2026-05-01T23:50:31Z
sync:
    github:
        issue_number: "619"
        synced_at: "2026-05-02T00:08:55Z"
---

## Repro

This input is correctly formatted and should not be changed:

```swift
            if lineIndex < 0 {
                lineIndex = 0
            } else if lineIndex >= rawLineLengths.count {
                lineIndex = rawLineLengths.count - 1
            }
```

But the formatter rewrites it to:

```swift
            if lineIndex < 0 {
                lineIndex = 0
            } else if lineIndex >= rawLineLengths.count
            {
                lineIndex = rawLineLengths.count - 1
            }
```

The opening brace of the `else if` body is being pushed to its own line. Expected: leave unchanged.

## Notes

- Likely related to brace-placement / break-precedence for `else if` conditions.
- See pretty-printer notes in CLAUDE.md (`maybeGroupAroundSubexpression`, `stackedIndentationBehavior`, `arrangeAssignmentBreaks`).



## Summary of Changes

The bug was already fixed by commit edef36bd (inline single-statement bodies on multi-line conditions and multi-pattern cases), which introduced the attachInlineBody path in visitIfExpr and the bodyIsInlineSingleStmt-aware top-level if wrapper in visitCodeBlockItem.

The reported repro came from the installed /opt/homebrew/bin/sm (version 3.0.2), which predates that fix. Running the same input through the current source build leaves it unchanged, both at file scope and nested inside a class+func.

Added regression test IfStmtTests.ifElseStatement_keepsInlineBraceWhenFits in Tests/SwiftiomaticTests/Layout/IfStmtTests.swift covering the users exact input at line length 100 with 4-space indentation. All 20 IfStmtTests pass.

User action: rebuild and reinstall sm to pick up the fix.
