---
# 46v-u5j
title: Inline compact-pipeline rule transforms; delete applyRewrite shim
status: ready
type: task
priority: high
created_at: 2026-04-30T00:45:06Z
updated_at: 2026-04-30T00:45:06Z
blocked_by:
    - uqb-m5z
sync:
    github:
        issue_number: "515"
        synced_at: "2026-04-30T00:55:13Z"
---

## Summary

Steps 2 and 3 from `uqb-m5z`. Now that the contained refactors landed, the next collapse is the per-decl-type wrapper layer.

## Plan

1. Inline each `rewrite<Type>(...)` wrapper from `Sources/SwiftiomaticKit/Rewrites/{Decls,Exprs,Stmts}/*.swift` directly into the corresponding `override func visit(_:)` method in `Sources/SwiftiomaticKit/Rewrites/CompactStageOneRewriter.swift` (the hand-written one — note: `wru-y41` already moved this file off the generator).
2. Delete `Context.applyRewrite` (`Sources/SwiftiomaticKit/Support/Context.swift:140-150`); the inlined call sites should call `<Rule>.transform(...)` directly, with `context.shouldRewrite(...)` gating in-line.
3. Delete the now-empty `Sources/SwiftiomaticKit/Rewrites/{Decls,Exprs,Stmts}/` directories.

## Estimated cost

`CompactStageOneRewriter.swift` grows from ~1.2k lines to ~4.5k lines. The 4.5k lines are pure data — alphabetised rule calls per node type — so the file becomes long but trivially scannable. Net codebase shrinks because each wrapper had its own header/trivia.

## Watchouts

- Some wrappers contain non-trivial inline logic beyond `applyRewrite` (e.g. `FunctionCallExpr.swift` widening rules, `SwitchExpr.swift` 305 lines, `ClassDecl.swift` `applyRedundantFinal` helper). Inline those carefully.
- Several rules use `willEnter`/`didExit` hooks alongside `transform`; those calls already live in `CompactStageOneRewriter.swift`. Don't double-call `transform`.
- Widening rules call `<Rule>.transform` directly (not through `applyRewrite`) and early-return when the result type changes — preserve that behavior.
