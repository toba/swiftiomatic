---
# n23-5ya
title: 'BlankLines: treat solitary closing brace as blank line'
status: ready
type: feature
priority: normal
created_at: 2026-04-24T15:18:04Z
updated_at: 2026-04-24T15:18:04Z
sync:
    github:
        issue_number: "368"
        synced_at: "2026-04-24T15:23:37Z"
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

- [ ] Add `closingBraceAsBlankLine` to `BlankLinesConfiguration`
- [ ] Update schema and config parsing
- [ ] Wire into blank-line rules that check for preceding blank lines
- [ ] Add tests for both `true` and `false` settings
- [ ] Regenerate schema (`swift run Generator`)
