---
# 6es-ckm
title: 'NestedCallLayout: collapse multi-arg calls and macro expansions'
status: completed
type: feature
priority: normal
created_at: 2026-05-08T01:39:09Z
updated_at: 2026-05-08T01:49:34Z
sync:
    github:
        issue_number: "643"
        synced_at: "2026-05-08T01:50:18Z"
---

Inline mode of NestedCallLayout currently only collapses nested call chains (>=2 deep) and single-arg hugs. It does not collapse:

1. Multi-arg single-level FunctionCallExprSyntax wrapped across lines (e.g. `foo(a: 1, b: 2,)` with newlines).
2. MacroExpansionExprSyntax / MacroExpansionDeclSyntax (e.g. `#externalMacro(module: ..., type: ...,)`) — these aren't visited by the rule at all.

## Tasks

- [x] Add failing tests for wrapped multi-arg call collapse
- [x] Add failing tests for wrapped #externalMacro collapse (expr + decl forms)
- [x] Extend NestedCallLayout.transform to also visit MacroExpansionExprSyntax (and MacroExpansionDeclSyntax if relevant)
- [x] Add a collapse-to-one-line path for wrapped multi-arg calls (when result fits within line length, and no comments/trailing closures)
- [x] Confirm tests pass and full suite is green (3224 passed)
- [x] Update CompactSyntaxRewriter dispatch / generated pipeline if needed for new node types



## Summary of Changes

- `Sources/SwiftiomaticKit/Rules/Wrap/NestedCallLayout.swift`: added `tryCollapseCallToOneLine` (multi-arg single-level FunctionCallExpr collapse) and `tryCollapseMacroExpansionToOneLine` plus a new `transform(_: MacroExpansionExprSyntax, ...)`. Detection uses arg/right-paren leading-trivia newlines (not `node.description`) so leading trivia from preceding context doesn't trigger spurious collapses on single-line nested calls. Excludes calls with trailing closures or any comments inside the arg list.
- `Sources/SwiftiomaticKit/Syntax/Rewriter/RewritePipeline.swift`: dispatch `NestedCallLayout.transform` from `visit(_: MacroExpansionExprSyntax)`.
- `Tests/SwiftiomaticTests/Rules/Wrap/NestedCallLayoutTests.swift`: new tests `collapsesWrappedMultiArgCall`, `collapsesWrappedMacroExpansion`, `wrappedMultiArgCallTooLongStaysWrapped`. Renamed `nonNestedCallUnchanged` → `wrappedNonNestedCallCollapsesWhenItFits` to match the new behavior.

MacroExpansionDeclSyntax was not wired up — the user's example (`#externalMacro(...)` as the rhs of a macro decl) is a `MacroExpansionExprSyntax`, not a decl. Decl form can be added later if needed.
