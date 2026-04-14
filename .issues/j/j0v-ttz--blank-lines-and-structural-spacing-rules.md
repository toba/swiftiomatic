---
# j0v-ttz
title: Blank lines and structural spacing rules
status: in-progress
type: feature
priority: normal
created_at: 2026-04-14T03:18:16Z
updated_at: 2026-04-14T16:22:49Z
parent: 77g-8mh
sync:
    github:
        issue_number: "291"
        synced_at: "2026-04-14T03:28:24Z"
---

Port blank-line and structural-spacing rules from SwiftFormat. Most of the basic spacing rules (around/inside delimiters, trailing whitespace, consecutive blanks) are already handled by the PrettyPrinter. These rules cover semantic spacing decisions NOT handled by the PrettyPrinter.

**Implementation**: These need either **PrettyPrinter enhancements** (adding tokens in `TokenStreamCreator.swift`) or new `SyntaxFormatRule` implementations. Study `TokenStreamCreator`'s existing blank-line handling before adding new behaviors. Some may require post-processing passes since the PrettyPrinter operates on a token stream, not the final output.

## Rules

- [ ] `blankLineAfterImports` — Insert blank line after the last import statement before other code
- [ ] `blankLineAfterSwitchCase` — Insert blank line after each switch case body (excluding last case)
- [ ] `blankLinesAfterGuardStatements` — Remove blanks between consecutive guards; insert blank after last guard
- [ ] `blankLinesAroundMark` — Insert blank line before and after `// MARK:` comments
- [ ] `blankLinesBetweenChainedFunctions` — Remove blank lines between chained function calls (keep linebreaks)
- [ ] `blankLinesBetweenImports` — Remove blank lines between consecutive import statements
- [ ] `blankLinesBetweenScopes` — Insert blank line before class/struct/enum/extension/protocol/function declarations
- [ ] `consistentSwitchCaseSpacing` — Ensure consistent blank-line spacing among all cases in a switch
- [ ] `leadingDelimiters` — Move leading `.` or `,` delimiters to end of previous line
- [ ] `linebreakAtEndOfFile` — Ensure file ends with exactly one newline
