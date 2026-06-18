---
# qrz-djm
title: 'Switch case wrapped in #if double-indented when indentConditionalCompilationBlocks is on'
status: completed
type: bug
priority: normal
created_at: 2026-06-18T02:12:01Z
updated_at: 2026-06-18T02:39:53Z
sync:
    github:
        issue_number: "732"
        synced_at: "2026-06-18T02:40:47Z"
---

When `indentConditionalCompilationBlocks: true`, a `case` wrapped in a `#if` directly inside a `switch` gets an extra indentation level relative to its sibling cases:

```
switch type {
#if os(macOS)
    case .rtf:        <- wrong: +1 extra
        return 1
#endif
case .markdown:       <- correct level
    return 2
}
```

The `#if`/`#endif` directives correctly align with the switch cases, but `visitIfConfigClause` adds an `.open` indentation for the clause contents. When those contents are switch cases (the IfConfigDecl is a direct element of a SwitchCaseListSyntax), the case labels should stay flush with sibling cases, so the conditional-compilation indentation must be suppressed.

Mirrors upstream apple/swift-format behaviour (code is identical) — this is a deliberate divergence.

## Tasks
- [x] Failing test in IfConfigTests asserting case-in-#if stays flush with indentConditionalCompilationBlocks=true
- [x] Fix visitIfConfigClause to use .same breaks when the enclosing IfConfigDecl is a SwitchCaseList element
- [x] Confirm normal (non-switch) #if blocks still indent
- [x] Full suite green



## Summary of Changes

**Fix:** `Sources/SwiftiomaticKit/Rules/Indentation/IndentConditionalCompilationBlocks.swift` — `visitIfConfigClause` now detects when the enclosing `IfConfigDecl` is a direct element of a `SwitchCaseListSyntax` (`node.parent?.parent?.parent?.is(SwitchCaseListSyntax.self)`) and, in that case, uses `.same` open/close breaks regardless of the `IndentConditionalCompilationBlocks` setting. This keeps a `case` wrapped in `#if` flush with its sibling cases; the conditional-compilation indent still applies to the case body and to normal (non-switch) `#if` blocks.

**Tests:**
- Added `IfConfigTests.poundIfWrappingSwitchCaseStaysFlushWhenIndentingBlocks` (iccb=true, asserts flush case).
- Updated `SwitchStmtTests.conditionalCases` expected output: the `#if`-wrapped case is now flush with siblings (it previously encoded the buggy indented form).
- `conditionalCasesIndenting` (indented switch-case style) unchanged — its case indent is governed by the `visitSwitchExpr` if-config wrap, not the clause open, so it was unaffected.

**Verification:** release `sm` reproduces the corrected output on the user's exact snippet (flush + iccb=true); full suite green (3457 passed, 0 failed).

Note: the closing-brace-alone closure layout reported alongside this is tracked separately as deferred bug **bhi-jt9**, with a quick-remind anchor comment in `TokenStream+Closures.swift::visitClosureExpr`.
