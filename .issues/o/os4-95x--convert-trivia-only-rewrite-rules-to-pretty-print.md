---
# os4-95x
title: Convert trivia-only rewrite rules to pretty-print layout
status: ready
type: epic
priority: normal
created_at: 2026-04-24T22:49:59Z
updated_at: 2026-04-25T00:14:04Z
sync:
    github:
        issue_number: "387"
        synced_at: "2026-04-25T01:59:55Z"
---

## Overview

Many `SyntaxFormatRule` (rewrite) rules only manipulate trivia — adding/removing newlines and whitespace — without making structural AST changes. These are candidates for conversion to the pretty-print layout system, which already handles whitespace decisions via the token stream. Moving them would:

- Eliminate redundant AST rewrites for whitespace-only concerns
- Consolidate all whitespace logic in the layout coordinator
- Reduce the number of sequential format-rule passes over the full tree
- Make behavior more predictable (one system decides all whitespace)

## Candidates

### Blank Line Rules (all trivia-only) — 10 rules

All modify `leadingTrivia`/`trailingTrivia` to insert or remove newlines. The layout system already has `MaximumBlankLines`, `ClosingBraceAsBlankLine`, and `CommentAsBlankLine` — these would extend that model.

- [ ] `BlankLinesAfterImports` — insert blank line after last import
- [x] `BlankLinesBetweenImports` — converted: maxBlankLines: 0 between consecutive imports in `visitCodeBlockItemList`
- [ ] `BlankLinesAfterGuardStatements` — blank line after last guard, none between consecutive guards
- [ ] `BlankLinesBetweenScopes` — blank lines between multi-line scoped declarations
- [ ] `BlankLinesBeforeControlFlow` — blank line before multi-line control flow
- [ ] `BlankLinesAroundMark` — blank lines before/after MARK comments
- [ ] `BlankLinesAfterSwitchCase` — blank line after multiline cases, none before closing brace
- [ ] `ConsistentSwitchCaseSpacing` — uniform blank lines between switch cases
- [x] `BlankLinesBetweenChainedFunctions` — converted: maxBlankLines: 0 on contextual breaks before `.` in chains
- [x] `NoEmptyLinesOpeningClosingBraces` — converted: `arrangeNonEmptyBraces()` with maxBlankLines: 0

### Wrap Rules (trivia-only subset) — 5 rules

These modify trivia to control line breaks. The layout system already decides where to break via `BreakKind` and `GroupBreakStyle`.

- [ ] `WrapConditionalAssignment` — newline after `=` in conditional assignments
- [ ] `WrapMultilineFunctionChains` — break at `.` in chained calls
- [ ] `WrapMultilineStatementBraces` — opening brace on new line for multiline statements
- [ ] `WrapCompoundCaseItems` — each case item on its own line
- [ ] `WrapSingleLineComments` — wrap long comments across lines

### Other — 1 rule

- [x] `EmptyBraces` — remove whitespace inside empty `{ }` braces → converted to `arrangeEmptyBraces()` in TokenStream+Helpers.swift

## Not Candidates

These rewrite rules make structural AST changes and cannot move to pretty-print:

- `WrapSingleLineBodies` — restructures statement collections when wrapping
- `WrapSwitchCaseBodies` — restructures statement collections when wrapping
- `NoSemicolons` — removes semicolon tokens (syntax node property)
- `RedundantReturn` — removes `return` keyword nodes
- All `Redundant/*`, `Sort/*`, `Conditions/*`, `Idioms/*`, `Access/*`, `Closures/*`, `Declarations/*`, `Generics/*`, `Hoist/*`, `Types/*` rules — these are structural transformations

## Approach

Each conversion involves:
1. Remove the `SyntaxFormatRule` implementation
2. Add corresponding logic in `TokenStream` visitor methods (emit appropriate `break`, `space`, or newline tokens)
3. Add a `LayoutRule` config struct if a new setting is needed
4. Verify existing tests pass against layout-driven output
5. Update generated files


## Analysis

After converting EmptyBraces and deeply analyzing the remaining 15 rules, most do NOT map cleanly to the layout model:

### Blocked: Need per-context blank line limits

The layout system only has global `MaximumBlankLines`. All 10 blank line rules need the ability to set a **local** max (e.g., 0 blank lines between imports, 1 blank line after guards). Converting these requires adding a new layout capability — a `maxBlankLines` parameter on break tokens or a context-scoped override.

### Blocked: Structural AST changes disguised as trivia

- `WrapConditionalAssignment` — moves the `=` token position, not just trivia
- `WrapCompoundCaseItems` — needs custom alignment indent (`case ` width) the layout indent model doesn't support
- `WrapSingleLineComments` — rewrites comment trivia pieces

### Already handled by pretty-printer (potentially redundant)

- `WrapMultilineStatementBraces` — the `break(.reset)` before `{` already wraps for multiline statements
- `WrapMultilineFunctionChains` — the `AroundMultilineExpressionChainComponents` setting already handles consistent chain wrapping

These could be removed if their behavior is verified to match the pretty-printer output.



### Not convertible: Insertion rules

The remaining 7 blank line rules INSERT blank lines (ensuring they exist) rather than removing them. The layout merge logic uses trivia counts over formatter counts, preventing the layout from forcing blank lines that don't exist in the source. These need a `minBlankLines` mechanism or should stay as rewrite rules:

- `BlankLinesAfterImports` — insert blank line after last import
- `BlankLinesAfterGuardStatements` — insert/remove around guard blocks
- `BlankLinesAfterSwitchCase` — insert after multiline cases
- `BlankLinesAroundMark` — insert around MARK comments
- `BlankLinesBeforeControlFlow` — insert before multiline control flow
- `BlankLinesBetweenScopes` — insert between scoped declarations
- `ConsistentSwitchCaseSpacing` — uniform spacing between switch cases
