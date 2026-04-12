---
# a88-mbv
title: Formatter strips backtick-quoted test names
status: completed
type: bug
priority: critical
created_at: 2026-04-12T18:33:30Z
updated_at: 2026-04-12T19:02:10Z
sync:
    github:
        issue_number: "227"
        synced_at: "2026-04-12T19:05:19Z"
---

The `sm format` command strips backticks from quoted test names (e.g. `func \`test something\`()`), breaking them. Backtick-quoted identifiers must be preserved during formatting.



## Root Cause

In this version of swift-syntax, `.identifier` tokens store backticks inside the associated string (e.g. `.identifier("`foo`")`). The rule was pattern-matching `case .identifier(let name)` but treating `name` as if backticks were stripped — so `isSwiftKeyword` checked "`foo`" (always false) and raw identifiers with spaces like "`test something`" also matched incorrectly.

## Fix

- Strip leading/trailing backticks from the identifier name before checking
- Validate the bare name is a valid Swift identifier (Unicode XID_Start/XID_Continue) — names with spaces or special characters need their backticks
- Check keyword status on the bare name, not the backtick-wrapped name
- Share the stripped name between visitor and rewriter via `redundantBackticksBareName`

## Tests Added

- `preservesBackticksOnTestNames` — `func `+"`test something`"+`() {}` must not trigger
- `preservesBackticksOnKeywords` — `let `+"`class`"+` = foo` must not trigger

## Summary of Changes

- `Sources/SwiftiomaticKit/Rules/Redundancy/Syntax/RedundantBackticksRule.swift` — fixed detection and correction logic
- `Tests/SwiftiomaticTests/Rules/Redundancy/RedundancySyntaxRuleTests.swift` — added 2 tests
