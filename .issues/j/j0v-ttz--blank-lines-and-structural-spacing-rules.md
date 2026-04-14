---
# j0v-ttz
title: Blank lines and structural spacing rules
status: completed
type: feature
priority: normal
created_at: 2026-04-14T03:18:16Z
updated_at: 2026-04-14T17:35:45Z
parent: 77g-8mh
sync:
    github:
        issue_number: "291"
        synced_at: "2026-04-14T18:45:52Z"
---

Port blank-line and structural-spacing rules from SwiftFormat. Most of the basic spacing rules (around/inside delimiters, trailing whitespace, consecutive blanks) are already handled by the PrettyPrinter. These rules cover semantic spacing decisions NOT handled by the PrettyPrinter.

**Implementation**: These need either **PrettyPrinter enhancements** (adding tokens in `TokenStreamCreator.swift`) or new `SyntaxFormatRule` implementations. Study `TokenStreamCreator`'s existing blank-line handling before adding new behaviors. Some may require post-processing passes since the PrettyPrinter operates on a token stream, not the final output.

## Rules

- [x] `blankLineAfterImports` — Insert blank line after the last import statement before other code
- [x] `blankLineAfterSwitchCase` — Insert blank line after each switch case body (excluding last case)
- [x] `blankLinesAfterGuardStatements` — Remove blanks between consecutive guards; insert blank after last guard
- [x] `blankLinesAroundMark` — Insert blank line before and after `// MARK:` comments
- [x] `blankLinesBetweenChainedFunctions` — Remove blank lines between chained function calls (keep linebreaks)
- [x] `blankLinesBetweenImports` — Remove blank lines between consecutive import statements
- [x] `blankLinesBetweenScopes` — Insert blank line before class/struct/enum/extension/protocol/function declarations
- [x] `consistentSwitchCaseSpacing` — Ensure consistent blank-line spacing among all cases in a switch
- [x] ~~`leadingDelimiters`~~ — Moved to c7r-77o (requires multi-token trivia manipulation)
- [x] `linebreakAtEndOfFile` — Ensure file ends with exactly one newline


## Summary of Changes

9 of 10 blank-line/structural-spacing rules ported: blankLineAfterImports, blankLineAfterSwitchCase, blankLinesAfterGuardStatements, blankLinesAroundMark, blankLinesBetweenChainedFunctions, blankLinesBetweenImports, blankLinesBetweenScopes, consistentSwitchCaseSpacing, linebreakAtEndOfFile. leadingDelimiters is blocked and tracked in c7r-77o.
