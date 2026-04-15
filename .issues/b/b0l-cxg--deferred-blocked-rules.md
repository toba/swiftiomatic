---
# b0l-cxg
title: Deferred blocked rules
status: completed
type: task
priority: normal
created_at: 2026-04-14T18:37:52Z
updated_at: 2026-04-14T22:59:32Z
parent: c7r-77o
sync:
    github:
        issue_number: "299"
        synced_at: "2026-04-15T00:34:45Z"
---

Rules deferred due to complexity or limited value.

- [x] `leadingDelimiters` — Move leading `.`/`,` to end of previous line. Multi-token trivia manipulation; trivial in flat token stream, complex in syntax tree. Parent: j0v-ttz.
- [x] `redundantLet` — Remove `let` from `let _ = expr`. Ties `let` to binding specifier.
- [x] `redundantStaticSelf` — Remove `Self.` prefix in static context. Node type change (`MemberAccessExprSyntax` → `DeclReferenceExprSyntax`).
- [x] `redundantType` — Remove redundant type annotation. Already a format rule; listed here for additional coverage (array/generic/closure patterns tracked in pfo-ol9).


## Summary of Changes

All four deferred rules implemented/upgraded as format rules with auto-fix, tests adapted from SwiftFormat:

1. **`leadingDelimiters`** (NEW) — Move leading `,`/`:` to end of previous line. Token-level trivia rearrangement with stored state for comment handling. 8 tests.
2. **`redundantLet`** (UPGRADED) — Added case pattern support (`if case .foo(let _)` → `if case .foo(_)`), attribute preservation (`@MainActor let _ = ...`). 23 tests.
3. **`redundantStaticSelf`** (CONVERTED lint→format) — `Self.bar()` → `bar()` in static contexts with proper nested function handling, initializer context preservation, and parameter shadowing detection. 18 tests.
4. **`redundantType`** (UPGRADED) — Added comment trivia transfer, broadened Void type detection, switch expression support, string interpolation. 37 tests.

Key learnings documented in /rule skill:
- SyntaxRewriter silently ignores covariant returns that change node kind — modify at parent level instead
- `is()`/`as()` type checks fail after child-first traversal — use `trimmedDescription` fallback
- Corrected AST reference for case pattern bindings (uses PatternExprSyntax, not LabeledExprSyntax.label)
