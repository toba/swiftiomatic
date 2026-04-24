---
# os4-95x
title: Convert trivia-only rewrite rules to pretty-print layout
status: ready
type: epic
priority: normal
created_at: 2026-04-24T22:49:59Z
updated_at: 2026-04-24T22:49:59Z
sync:
    github:
        issue_number: "387"
        synced_at: "2026-04-24T22:54:05Z"
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
- [ ] `BlankLinesBetweenImports` — remove blank lines between consecutive imports
- [ ] `BlankLinesAfterGuardStatements` — blank line after last guard, none between consecutive guards
- [ ] `BlankLinesBetweenScopes` — blank lines between multi-line scoped declarations
- [ ] `BlankLinesBeforeControlFlow` — blank line before multi-line control flow
- [ ] `BlankLinesAroundMark` — blank lines before/after MARK comments
- [ ] `BlankLinesAfterSwitchCase` — blank line after multiline cases, none before closing brace
- [ ] `ConsistentSwitchCaseSpacing` — uniform blank lines between switch cases
- [ ] `BlankLinesBetweenChainedFunctions` — remove blank lines in method chains
- [ ] `NoEmptyLinesOpeningClosingBraces` — remove blank lines inside braces

### Wrap Rules (trivia-only subset) — 5 rules

These modify trivia to control line breaks. The layout system already decides where to break via `BreakKind` and `GroupBreakStyle`.

- [ ] `WrapConditionalAssignment` — newline after `=` in conditional assignments
- [ ] `WrapMultilineFunctionChains` — break at `.` in chained calls
- [ ] `WrapMultilineStatementBraces` — opening brace on new line for multiline statements
- [ ] `WrapCompoundCaseItems` — each case item on its own line
- [ ] `WrapSingleLineComments` — wrap long comments across lines

### Other — 1 rule

- [ ] `EmptyBraces` — remove whitespace inside empty `{ }` braces (trivia-only)

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
