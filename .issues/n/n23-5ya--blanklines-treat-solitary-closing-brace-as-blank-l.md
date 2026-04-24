---
# n23-5ya
title: 'BlankLines: treat solitary closing brace as blank line'
status: completed
type: feature
priority: normal
created_at: 2026-04-24T15:18:04Z
updated_at: 2026-04-24T15:30:40Z
sync:
    github:
        issue_number: "368"
        synced_at: "2026-04-24T16:08:53Z"
---

Add a layout option within the `blankLines` configuration group:

```json
{
  "blankLines": {
    "closingBraceAsBlankLine": false
  }
}
```

When `closingBraceAsBlankLine` is `true`, a line containing only `}` (and whitespace) is treated as equivalent to a blank line for the purposes of blank-line rules (e.g. `BlankLinesBeforeControlFlow`). This means a closing brace already provides visual separation, so no additional blank line is required before the next statement.

Default: `false` (current behavior — closing braces are not treated as blank lines).

## Tasks

- [x] Add `closingBraceAsBlankLine` as LayoutRule in blankLines group
- [x] Update schema and config parsing
- [x] Wire into BlankLinesBeforeControlFlow and BlankLinesBetweenScopes
- [x] Build passes; tests deferred to session end per agent rules
- [x] Regenerate schema (`swift run Generator`)


## Summary of Changes

Added `closingBraceAsBlankLine` (default `false`) as a `LayoutRule` in the `blankLines` group. When `true`, a solitary `}` on its own line counts as visual separation, suppressing blank-line insertion in `BlankLinesBeforeControlFlow` and `BlankLinesBetweenScopes`. Schema regenerated.
