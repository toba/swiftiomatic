---
# nzo-061
title: Add UpdateLineBreak umbrella config category
status: completed
type: task
priority: normal
created_at: 2026-04-18T00:27:31Z
updated_at: 2026-04-18T00:30:23Z
sync:
    github:
        issue_number: "327"
        synced_at: "2026-04-23T05:30:22Z"
---

Group lineBreak* pretty-print settings and LinebreakAtEndOfFile rule under UpdateLineBreak umbrella config category.

- [x] Add UpdateLineBreak to umbrellaGroups
- [x] Add decode/encode handling for lineBreak* settings in umbrella
- [x] Remove lineBreak* from FormatSettings encoding
- [x] Add UpdateLineBreak to FormatSettings.keyNames
- [x] Update schema generator
- [x] Update tests


## Summary of Changes

Added `UpdateLineBreak` umbrella config category that groups the `LinebreakAtEndOfFile` rule and all 5 `lineBreak*` pretty-print settings (`beforeControlFlowKeywords`, `beforeEachArgument`, `beforeEachGenericRequirement`, `betweenDeclarationAttributes`, `aroundMultilineExpressionChainComponents`). Follows the same pattern as `UpdateBlankLines`. Backwards compat preserved—top-level `lineBreak*` keys still decode correctly.
