---
# 1jq-aka
title: 'Switch case inside #if loses switch-body indentation'
status: scrapped
type: bug
priority: normal
created_at: 2026-06-27T16:11:31Z
updated_at: 2026-06-27T16:15:32Z
sync:
    github:
        issue_number: "745"
        synced_at: "2026-06-27T16:17:04Z"
---

Surfaced while porting swift-format #1225 (issue mid-kqi). Pre-existing, separate from the #endif merge fix.

## Repro
Config: respectsExistingLineBreaks=false, 2-space indent.

Input:
```
switch x {
#if A
case 1: f()
#endif
}
```

Our output (case stays at column 0):
```
switch x {
#if A
case 1: f()
#endif
}
```

Upstream swift-format (#1225 test) indents the case as a normal switch-body member:
```
switch x { #if A
  case 1: f()
#endif
}
```

## Expected
`case 1: f()` should receive the switch-body indentation (2 spaces) even though it is wrapped in an `#if ... #endif`. The `#if`/`#endif` marker indentation is governed separately by indentConditionalCompilationBlocks.

## Notes
- Reproduces regardless of indentConditionalCompilationBlocks (true or false).
- Likely in the switch-case arrangement / IfConfigDecl-in-switch handling (TokenStream+ControlFlow.swift around the `for ifConfigDecl in node.cases` loop, ~line 370).
- Tasks:
  - [ ] Add failing test
  - [ ] Diagnose indentation suppression
  - [ ] Fix and verify

## Reasons for Scrapping

Not a bug — this is an **intentional** Swiftiomatic divergence from upstream swift-format.

Commit `0dcd5602` deliberately added the `wrapsSwitchCases` suppression in `visitIfConfigClause` (IndentConditionalCompilationBlocks.swift) to *fix* a double-indent: a `case` wrapped in `#if` should stay flush with its sibling cases, not be pushed one level deeper by the conditional-compilation indent. The case *body* is still indented normally; only the extra `#if`-level indent on the label is suppressed.

Upstream swift-format has no such suppression and always indents the `#if` contents (so its #1225 test shows `  case 1: f()` indented). Swiftiomatic's flush-with-siblings layout is the considered, preferred behavior. My original 'divergence' note misread upstream's expected output as the correct target.

Verified: `visitSwitchExpr`/`visitSwitchCase` match upstream verbatim; the only intentional difference is `wrapsSwitchCases`.
