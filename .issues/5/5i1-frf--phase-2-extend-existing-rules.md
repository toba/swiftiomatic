---
# 5i1-frf
title: 'Phase 2: Extend existing rules'
status: completed
type: task
priority: normal
created_at: 2026-04-14T18:36:37Z
updated_at: 2026-04-14T19:16:37Z
parent: c7r-77o
sync:
    github:
        issue_number: "305"
        synced_at: "2026-04-14T18:45:54Z"
---

Require architectural decisions about modifying existing rules vs standalone.

- [x] `redundantFileprivate` — Prefer `private` over `fileprivate` where equivalent. Requires extending `FileScopedDeclarationPrivacy` for non-file-scope contexts. Parent: nnl-svw.
- [x] `redundantParens` — Remove redundant parentheses beyond conditions. Requires extending `NoParensAroundConditions` for return statements, assignments, etc. Parent: nnl-svw.

## Summary of Changes

- **`redundantFileprivate`**: New opt-in format rule (`RedundantFileprivate`). Two-phase file analysis: determines if file has single logical type (+ same-name extensions), then replaces `fileprivate` with `private` on members. Skips files with nested types, multiple type declarations, or top-level code. 30 tests adapted from SwiftFormat.
- **`redundantParens`**: Extended existing `NoParensAroundConditions` format rule with `ReturnStmtSyntax` and `InitializerClauseSyntax` visitors. Removes `(expr)` from `return (expr)` and `let x = (expr)`. Preserves parens around trailing closures and immediately-called closures. Fixed `super.visit` fallback for nested if/switch expressions. 18 new tests.
