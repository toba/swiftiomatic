---
# 46v-u5j
title: Inline compact-pipeline rule transforms; delete applyRewrite shim
status: in-progress
type: task
priority: high
created_at: 2026-04-30T00:45:06Z
updated_at: 2026-04-30T01:11:22Z
blocked_by:
    - uqb-m5z
sync:
    github:
        issue_number: "515"
        synced_at: "2026-04-30T01:11:24Z"
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



## Progress (round 1)

Inlined 9 of the simpler wrappers into `CompactStageOneRewriter.swift` and deleted their files:

- `Decls/AccessorBlock.swift` (`ProtocolAccessorOrder`)
- `Decls/AccessorDecl.swift` (`WrapSingleLineBodies`)
- `Decls/DeinitializerDecl.swift` (`ModifiersOnSameLine`, `TripleSlashDocComments`, `WrapMultilineStatementBraces`)
- `Stmts/DoStmt.swift` (`WrapMultilineStatementBraces`)
- `Exprs/TernaryExpr.swift` (`NoVoidTernary`, `WrapTernary`)
- `Exprs/ClosureExpr.swift` (`RedundantReturn`, `UnusedArguments`)
- `Stmts/WhileStmt.swift` (`NoParensAroundConditions`, `WrapMultilineStatementBraces`, `WrapSingleLineBodies`)
- `Stmts/GuardStmt.swift` (same trio)
- `Stmts/RepeatStmt.swift` (`NoParensAroundConditions`, `WrapSingleLineBodies`)

`context.applyRewrite` is still alive — call sites moved into `CompactStageOneRewriter.swift` but kept the shim. Deletion of `applyRewrite` is still pending.

### Remaining

- Decls: `ActorDecl`, `ClassDecl` (has `applyRedundantFinal` helper to relocate), `EnumDecl`, `ExtensionDecl`, `FunctionDecl` (has `NoForceTry.afterFunctionDecl` / `NoForceUnwrap.afterFunctionDecl` calls), `ImportDecl`, `InitializerDecl`, `ProtocolDecl`, `StructDecl` (`StaticStructShouldBeEnum` widening), `SubscriptDecl`, `VariableDecl`
- Exprs: `AsExpr`, `ClosureSignature`, `DeclReferenceExpr`, `ForceUnwrapExpr`, `FunctionCallExpr` (multiple widening branches), `FunctionSignature`, `FunctionType` (has `applyPreferVoidReturn` helper used by `ClosureSignature.swift` — needs to migrate into `PreferVoidReturn` rule), `GenericSpecializationExpr`, `IdentifierType`, `InfixOperatorExpr`, `InitializerClause`, `IsExpr`, `MemberAccessExpr` (multiple widening branches), `PrefixOperatorExpr`, `StringLiteralExpr`, `SubscriptCallExpr`, `TryExpr`
- Stmts: `CodeBlock`, `CodeBlockItemList`, `ConditionElement`, `ForStmt`, `IfExpr`, `ReturnStmt`, `SwitchCase`, `SwitchCaseList`, `SwitchExpr` (305 lines), and the existing `Tokens/`/`Files/` wrappers if they exist.

Deferring step 3 (delete `applyRewrite`) until all wrappers are inlined; collapsing both at once is cleaner than two passes.

### Validation

- `swift_package_test` clean: 3010 passed, 0 failed.
