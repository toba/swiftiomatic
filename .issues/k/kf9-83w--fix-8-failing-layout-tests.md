---
# kf9-83w
title: Fix 8 failing layout tests
status: review
type: bug
priority: normal
created_at: 2026-04-28T00:22:40Z
updated_at: 2026-04-28T00:45:41Z
sync:
    github:
        issue_number: "474"
        synced_at: "2026-04-28T02:39:59Z"
---

Build succeeds. 8 tests fail in the layout/pretty-print suite — all related to guard/condition wrapping and string handling.

## Failing tests

- [x] `AlignWrappedConditionsTests.guardAlignsTwoConditions` (line 127)
- [x] `AlignWrappedConditionsTests.guardNestedIndentation` (line 147)
- [x] `AlignWrappedConditionsTests.guardBeforeGuardConditionsUsesNormalIndent` (line 175)
- [x] `AlignWrappedConditionsTests.guardBeforeGuardConditionsNestedUsesNormalIndent` (line 197)
- [x] `GuardStmtTests.openBraceIsGluedToElseKeyword` (line 128)
- [x] `GuardStmtTests.continuationLineBreaking` (line 201)
- [x] `GuardStmtTests.compoundExpressionBreakPrecedence` (line 374)
- [x] `StringTests.multilineStringsNestedInAnotherWrappingContext` (line 759)

## Notes

All failures report "Pretty-printed result was not what was expected." Most cluster around guard-condition wrapping — likely a single regression in break precedence / `BeforeGuardConditions` token placement. See CLAUDE.md "Layout & Break Precedence" section and `.issues/w/we9-2fx`, `.issues/w/wq2-tuv` for prior context.

Investigate the guard tests first — the string test may be an unrelated independent failure, or may share a root cause via inner-break chunk bounding.



## Investigation update

Tried the planned 'one-line revert' (restore .close to after rightBrace, drop printerControl). Results:

- 6 of 8 originally-failing tests pass (the wrap-conditions-with-non-fitting-inline-body cases).
- BUT 5 originally-passing tests now fail (the inline-collapse-when-it-fits cases): collapsesElseOntoConditionLineWhenItFits, attachesInlineElseToWrappedConditions's twin breaksElseWhenInlineBodyExceedsLineLength, discretionaryElseBreakIgnoredWhenFits, guardWithInlineBodyWrapsBodyNotElse, optionalBindingConditions, multilineStringWithInterpolations.
- compoundExpressionBreakPrecedence still fails in both configurations.

Net: 8 failures → 7 failures, but with a different (regressed) set. Restored working tree to pre-edit state.

## Conflicting expectations

Two valid behaviors compete in BeforeGuardConditions's inline-body branch:

| Scenario | Inline form fits | Expected |
|---|---|---|
| collapsesElseOntoConditionLineWhenItFits | yes | else glued |
| breaksElseWhenInlineBodyExceedsLineLength | no, but `else {` fits | else glued, body wraps |
| attachesInlineElseToWrappedConditions | yes (with wrapped conditions) | else glued |
| guardAlignsTwoConditions, openBraceIsGluedToElseKeyword, etc. | no | else on new line |

The distinguishing factor isn't simply 'does inline form fit' — it depends on body-internal break precedence vs. the elective break before `else`. Per CLAUDE.md, the precedence trick is .open placement: putting .open AFTER the break bounds its chunk to inner breaks, making outer fire LAST. The current and reverted code both place .open BEFORE the break.

## Likely fix path (not yet attempted)

1. Move `.open` to AFTER the `.break(.same)` before `else`, so its chunk is bounded by inner body breaks — outer break fires only as last resort.
2. Keep `.close` after rightBrace so the bounded group still spans `else { stmt }`.
3. Possibly adjust whether the inner body uses `.same` vs `.open` to control precedence ordering between body-wrap and else-wrap.
4. compoundExpressionBreakPrecedence may need a separate look — it involves compound boolean expressions where the first-condition .open-skip path applies (line 33-36 in BeforeGuardConditions.swift).



## Summary of Changes

All 8 originally-failing tests now pass. Two changes:

1. `Sources/SwiftiomaticKit/Extensions/CodeBlockSyntax+Convenience.swift`: added `hasInlineIntentSingleStatementBody` — stricter sibling of `isInlineSingleStatementBody` that also requires no newlines in the trivia between `{`, the statement, and `}` (i.e. user's input had body truly inline).

2. `Sources/SwiftiomaticKit/Rules/LineBreaks/BeforeGuardConditions.swift`: in `visitGuardStmt`, route to the inline-glue branch only when `hasInlineIntentSingleStatementBody` is true AND `AlignWrappedConditions` is disabled. This makes `AlignWrappedConditions` always force `else` to a new line on wrap (matching `if`-stmt style) and routes multi-line-input bodies through the `.reset` branch (forcing `else` to break when conditions wrap).

## Known follow-up

Test suite went from 8 failures → 2 failures. Net: −6.

The two new failures are **idempotency** failures (not output-mismatch) in:
- `GuardStmtTests.breaksElseWhenInlineBodyExceedsLineLength` (line 473)
- `GuardStmtTests.optionalBindingConditions` (line 233)

Both have inline-body input. Pass 1 correctly produces `... else {\n  stmt\n}` (else glued, body wrapped). Pass 2 sees a multi-line body indistinguishable from cases like `openBraceIsGluedToElseKeyword` whose expectation is else-on-new-line. There is no syntactic signal that survives Pass 1 and disambiguates the two intents.

These test expectations are arguably aspirational — no idempotent formatter design can satisfy both test groups simultaneously. Suggested follow-up: relax these two tests' expected output to match the `.reset` branch behavior (else on its own line when body wraps), matching the existing `multiStatementBodyAlwaysBreaksElse` test.
