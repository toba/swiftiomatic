---
# xuy-4wl
title: Wrapping and body formatting rules
status: ready
type: feature
priority: normal
created_at: 2026-04-14T03:18:17Z
updated_at: 2026-04-14T03:18:17Z
parent: 77g-8mh
sync:
    github:
        issue_number: "286"
        synced_at: "2026-04-14T03:28:23Z"
---

Port wrapping and body-formatting rules from SwiftFormat. Basic line wrapping and argument wrapping are already handled by the PrettyPrinter. These cover more specific wrapping semantics.

**Implementation**: Some can be `SyntaxFormatRule` rewrites (expanding single-line bodies to multi-line). Others may need **PrettyPrinter enhancements** in `TokenStreamCreator.swift`. The PrettyPrinter already supports `lineBreakAroundMultilineExpressionChainComponents` which partially addresses chained functions.

## Rules

- [ ] `wrapConditionalBodies` — Wrap inline `if`/`guard` bodies onto new lines
- [ ] `wrapFunctionBodies` — Wrap single-line function/init/subscript bodies onto multiple lines
- [ ] `wrapLoopBodies` — Wrap inline `for`/`while`/`repeat` loop bodies onto new lines
- [ ] `wrapMultilineConditionalAssignment` — Wrap multiline conditional assignment after the `=` operator
- [ ] `wrapMultilineFunctionChains` — Ensure chained calls are all on one line or one per line
- [ ] `wrapMultilineStatementBraces` — Wrap opening brace of multiline statements onto new line
- [ ] `wrapPropertyBodies` — Wrap single-line computed property bodies onto multiple lines
- [ ] `wrapSingleLineComments` — Wrap `//` comments exceeding max line width
- [ ] `wrapSwitchCases` — Wrap comma-delimited switch cases onto separate lines
