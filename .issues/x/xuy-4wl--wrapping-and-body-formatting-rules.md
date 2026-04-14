---
# xuy-4wl
title: Wrapping and body formatting rules
status: completed
type: feature
priority: normal
created_at: 2026-04-14T03:18:17Z
updated_at: 2026-04-14T18:34:07Z
parent: 77g-8mh
sync:
    github:
        issue_number: "286"
        synced_at: "2026-04-14T18:45:51Z"
---

Port wrapping and body-formatting rules from SwiftFormat. Basic line wrapping and argument wrapping are already handled by the PrettyPrinter. These cover more specific wrapping semantics.

**Implementation**: Some can be `SyntaxFormatRule` rewrites (expanding single-line bodies to multi-line). Others may need **PrettyPrinter enhancements** in `TokenStreamCreator.swift`. The PrettyPrinter already supports `lineBreakAroundMultilineExpressionChainComponents` which partially addresses chained functions.

## Rules

- [x] `wrapConditionalBodies` — Wrap inline `if`/`guard` bodies onto new lines
- [x] `wrapFunctionBodies` — Wrap single-line function/init/subscript bodies onto multiple lines
- [x] `wrapLoopBodies` — Wrap inline `for`/`while`/`repeat` loop bodies onto new lines
- [ ] `wrapMultilineConditionalAssignment` → blocked (c7r-77o Phase 8) — Wrap multiline conditional assignment after the `=` operator
- [ ] `wrapMultilineFunctionChains` → blocked (c7r-77o Phase 8) — Ensure chained calls are all on one line or one per line
- [ ] `wrapMultilineStatementBraces` → blocked (c7r-77o Phase 8) — Wrap opening brace of multiline statements onto new line
- [x] `wrapPropertyBodies` — Wrap single-line computed property bodies onto multiple lines
- [ ] `wrapSingleLineComments` → blocked (c7r-77o Phase 8) — Wrap `//` comments exceeding max line width
- [x] `wrapSwitchCases` — Wrap comma-delimited switch cases onto separate lines


## Summary of Changes

5 wrapping rules implemented as opt-in `SyntaxFormatRule` format rules with auto-fix:

| Rule | Tests | Key Detail |
|------|-------|-----------|
| `WrapConditionalBodies` | 16 | if/guard/else bodies, nested chains, stateful indent tracking |
| `WrapLoopBodies` | 10 | for/while/repeat bodies, nested loops |
| `WrapFunctionBodies` | 14 | func/init/subscript bodies, implicit getter wrapping |
| `WrapPropertyBodies` | 11 | computed properties, didSet/willSet observers, protocol skip |
| `WrapSwitchCases` | 7 | comma-delimited case items, `case ` alignment |

Shared helpers extracted to `SyntaxProtocol+Convenience.swift`:
- `CodeBlockSyntax.bodyNeedsWrapping` / `.wrappingBody(baseIndent:)`
- `Trivia.indentation` / `.trimmingTrailingWhitespace`

4 rules deferred to PrettyPrinter enhancements (c7r-77o Phase 8).
