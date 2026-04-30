---
# n8q-3pp
title: guard else { stmt } not inlined when alignWrappedConditions=true
status: completed
type: bug
priority: normal
created_at: 2026-04-30T03:56:58Z
updated_at: 2026-04-30T04:08:15Z
blocked_by:
    - n6q-htv
sync:
    github:
        issue_number: "525"
        synced_at: "2026-04-30T04:23:38Z"
---

## Problem

Issue n6q-htv added inline-attach for `guard ... else { stmt }` when conditions wrap, but the fix is gated on `!config[AlignWrappedConditions.self]`. Under this project's configuration (`beforeGuardConditions=false`, `alignWrappedConditions=true`) the gate excludes the fix.

Real-case example, `Sources/SwiftiomaticKit/Rules/Conditions/DuplicateConditions.swift:45-47`:

\`\`\`swift
guard let switchCase = element.as(SwitchCaseSyntax.self),
      case let .case(label) = switchCase.label
else { continue }
\`\`\`

Should be:

\`\`\`swift
guard let switchCase = element.as(SwitchCaseSyntax.self),
      case let .case(label) = switchCase.label else { continue }
\`\`\`

## Plan

Drop the `alignWrappedConditions` gate in `BeforeGuardConditions.swift` (line 59). Change the break kind in the inline branch from `.same` to `.reset` so a too-long body still drops `else` to base indent (column 0) under aligned conditions. The outer `.open(.inconsistent)` group still controls fits-or-breaks.

## Tasks

- [x] Add failing tests under aligned-conditions configuration (fits + overflow)
- [x] Drop the gate (kept `.same` — `.reset` always breaks)
- [x] Verify on `DuplicateConditions.swift` that the user-reported case inlines
- [x] Full suite passes (3005 / 3005)



## Summary of Changes

Dropped the `!config[AlignWrappedConditions.self]` gate in `Sources/SwiftiomaticKit/Rules/LineBreaks/BeforeGuardConditions.swift` so the inline-attach branch applies regardless of alignment mode. Kept the `.same` break kind — initial attempt to switch to `.reset` broke the existing inline-attach behavior because `.reset` forces the break to fire. The outer `.open(.inconsistent)` group spanning past `leftBrace` is what controls the fits-or-breaks decision; the break kind only affects landing column when broken, and `.same` lands at base indent fine after the conditions' alignment group closes.

### Tests

- `Tests/SwiftiomaticTests/Layout/GuardStmtTests.swift` — added `attachesInlineElseUnderAlignedConditions` and `breaksElseUnderAlignedConditionsWhenBodyTooLong` with `alignWrappedConditions=true, beforeGuardConditions=false`.
- `Tests/SwiftiomaticTests/Layout/AlignWrappedConditionsTests.swift` — updated 4 existing tests (`guardAlignsTwoConditions`, `guardNestedIndentation`, `guardBeforeGuardConditionsUsesNormalIndent`, `guardBeforeGuardConditionsNestedUsesNormalIndent`) to expect the new `else { ... }` glue behavior, matching the form already used by `breaksElseWhenInlineBodyExceedsLineLength`.
- Full suite: 3005 passed, 0 failed.

### Verified end-to-end

Running `.build/debug/sm format --configuration swiftiomatic.json Sources/SwiftiomaticKit/Rules/Conditions/DuplicateConditions.swift` now produces the expected inline `else { continue }`.
