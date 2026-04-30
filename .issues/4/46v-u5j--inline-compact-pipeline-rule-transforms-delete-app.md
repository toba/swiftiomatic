---
# 46v-u5j
title: Inline compact-pipeline rule transforms; delete applyRewrite shim
status: completed
type: task
priority: high
created_at: 2026-04-30T00:45:06Z
updated_at: 2026-04-30T02:08:23Z
blocked_by:
    - uqb-m5z
sync:
    github:
        issue_number: "515"
        synced_at: "2026-04-30T02:10:47Z"
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



## Progress (round 2)

Inlined a further 19 wrappers and deleted their files (28 total this issue):

- `Decls/AccessorDecl.swift`, `Decls/AccessorBlock.swift`, `Decls/DeinitializerDecl.swift`
- `Stmts/DoStmt.swift`, `Stmts/WhileStmt.swift`, `Stmts/GuardStmt.swift`, `Stmts/RepeatStmt.swift`, `Stmts/ConditionElement.swift`, `Stmts/ForStmt.swift`, `Stmts/IfExpr.swift`, `Stmts/ReturnStmt.swift`, `Stmts/SwitchCase.swift`, `Stmts/CodeBlock.swift`
- `Exprs/TernaryExpr.swift`, `Exprs/ClosureExpr.swift`, `Exprs/AsExpr.swift`, `Exprs/IsExpr.swift`, `Exprs/StringLiteralExpr.swift`, `Exprs/DeclReferenceExpr.swift`, `Exprs/TryExpr.swift`, `Exprs/SubscriptCallExpr.swift`, `Exprs/ForceUnwrapExpr.swift`, `Exprs/IdentifierType.swift`, `Exprs/GenericSpecializationExpr.swift`, `Exprs/InitializerClause.swift`, `Exprs/PrefixOperatorExpr.swift`, `Exprs/InfixOperatorExpr.swift`, `Exprs/MemberAccessExpr.swift`

### Helper migrations

- `applyBlankLinesAfterGuardStatements` (and its `Finding.Message` extensions) moved into `BlankLinesAfterGuardStatements.apply(_:context:)` so the rule owns its full body.
- `Finding.Message.doNotForceCast(name:)` promoted to internal scope on `NoForceCast` (was duplicated as `fileprivate` in both `AsExpr.swift` and `NoForceUnwrap.swift`; deleted the `NoForceUnwrap.swift` copy since the rule no longer references it).

### Remaining

- **Decls (11 files)**: `ActorDecl`, `ClassDecl` (has `applyRedundantFinal` helper), `EnumDecl`, `ExtensionDecl`, `FunctionDecl` (has `NoForceTry.afterFunctionDecl` / `NoForceUnwrap.afterFunctionDecl` calls), `ImportDecl`, `InitializerDecl`, `ProtocolDecl`, `StructDecl` (`StaticStructShouldBeEnum` widening), `SubscriptDecl`, `VariableDecl`
- **Exprs (4 files)**: `FunctionCallExpr` (510 lines, multiple widening branches), `FunctionType` + `ClosureSignature` (share `applyPreferVoidReturn` / `hasNonWhitespaceTrivia` / `makeVoidIdentifierType` helpers — needs migration into `PreferVoidReturn` rule), `FunctionSignature` (private `applyNoVoidReturnOnFunctionSignature` helper — needs migration into `NoVoidReturnOnFunctionSignature` rule)
- **Stmts (3 files)**: `CodeBlockItemList`, `SwitchCaseList`, `SwitchExpr` (305 lines)
- **Step 3 — delete `Context.applyRewrite`** still pending; once all wrappers are inlined this can be a single mechanical pass.

### Validation

- `swift_package_test` clean: 3010 passed, 0 failed.



## Progress (round 3)

Inlined the remaining 18 wrappers and removed all three wrapper directories. Migrated their non-trivial helpers into the rules they belong to.

### Inlined and deleted

- **Decls (11)**: `ActorDecl`, `ClassDecl`, `EnumDecl`, `ExtensionDecl`, `FunctionDecl`, `ImportDecl`, `InitializerDecl`, `ProtocolDecl`, `StructDecl`, `SubscriptDecl`, `VariableDecl`
- **Exprs (4)**: `ClosureSignature`, `FunctionCallExpr`, `FunctionSignature`, `FunctionType`
- **Stmts (3)**: `CodeBlockItemList`, `SwitchCaseList`, `SwitchExpr`

`Sources/SwiftiomaticKit/Rewrites/{Decls,Exprs,Stmts}/` are gone (step 3 complete).

### Helper migrations into rule classes

- `applyRedundantFinal` → `RedundantFinal.apply`
- `applyPreferAnyObject` → `PreferAnyObject.apply`
- `applyStrongOutlets` (+ `hasIBOutletAttribute`) → `StrongOutlets.apply`
- `applyPreferVoidReturn` / `applyPreferVoidReturnToClosureSignature` (+ shared `hasNonWhitespaceTrivia`/`makeVoidIdentifierType`) → `PreferVoidReturn.apply` (overloaded for `FunctionTypeSyntax` and `ClosureSignatureSyntax`)
- `applyNoVoidReturnOnFunctionSignature` → `NoVoidReturnOnFunctionSignature.apply`
- `applyNoTrailingClosureParens` → `NoTrailingClosureParens.apply`
- `applyPreferTrailingClosures` (+ all helpers) → `PreferTrailingClosures.apply`
- `applyWrapMultilineFunctionChains` (+ all helpers and `PeriodTriviaRewriter`) → `WrapMultilineFunctionChains.apply`
- `applyPreferEarlyExits` (+ `codeBlockEndsWithEarlyExit`) → `PreferEarlyExits.apply`
- `applyNoFallThroughOnlyCases` (+ all helpers) → `NoFallThroughOnlyCases.apply` (with `applyImpl` shared between `apply` and `willEnter`)
- `applyBlankLinesAfterSwitchCase` → `BlankLinesAfterSwitchCase.apply`
- `applyConsistentSwitchCaseSpacing` → `ConsistentSwitchCaseSpacing.apply`
- `applySwitchCaseIndentation` (+ `reindentCase`/`replaceIndentation`/`lineIndentation`) → `SwitchCaseIndentation.apply`

### Remaining

**Step 2 — delete `Context.applyRewrite`** still pending. The shim is still alive at 161 call sites in `CompactStageOneRewriter.swift`. Inlining each is mechanical:

```swift
context.applyRewrite(R.self, to: &n, parent: parent, transform: R.transform)
```
becomes
```swift
if context.shouldRewrite(R.self, at: Syntax(n)),
   let next = R.transform(n, parent: parent, context: context).as(type(of: n)) {
  n = next
}
```

(For non-widening rules — most of them — the `.as(...)` narrowing is unnecessary and the simpler `n = R.transform(n, parent: parent, context: context)` works.) Deferred to a follow-up because the rule-by-rule signature audit doesn't fit cleanly with the wrapper-deletion work.

### Validation

- `swift_package_test` clean: 3010 passed, 0 failed.



## Progress (round 4 — completion)

Step 2 (delete `Context.applyRewrite`) is done. All 161 call sites in `CompactStageOneRewriter.swift` were rewritten to use `shouldRewrite` + `.transform(...).as(NodeType.self)` directly. The shim `applyRewrite` has been removed from `Context.swift`.

The conversion was driven by a Python script that:
1. Walked the file, tracking each `if/guard var concrete = visited.as(NodeType.self)` binding and `var result = super.visit(node)` (typed by the visit's return type) so we could resolve each call site's variable type.
2. Replaced each `context.applyRewrite(R.self, to: &VAR, parent: parent, transform: R.transform)` with the explicit `if context.shouldRewrite(R.self, at: Syntax(VAR)), let next = R.transform(VAR, parent: parent, context: context).as(NodeType.self) { VAR = next }` form.

Six sites under `guard var concrete = visited.as(...) else { return ... }` weren't bound by the script (it only tracked `if var`) and were fixed by hand: three in `InfixOperatorExpr` (`NoAssignmentInExpressions`, `NoYodaConditions`, `PreferCompoundAssignment`, `WrapConditionalAssignment`) and two in `MemberAccessExpr` (`PreferIsDisjoint`, `PreferSelfType`).

### Validation

- `swift_package_build` clean.
- `swift_package_test` clean: 3010 passed, 0 failed.

## Summary of Changes

- Inlined every per-decl-type `rewrite<NodeType>` wrapper from `Sources/SwiftiomaticKit/Rewrites/{Decls,Exprs,Stmts}/` directly into `CompactStageOneRewriter.visit(_:)` overrides (28 files across three rounds, 161 transform call sites).
- Migrated 14 wrapper-private helpers into the rules they belong to: `RedundantFinal.apply`, `PreferAnyObject.apply`, `StrongOutlets.apply`, `PreferVoidReturn.apply` (overloaded), `NoVoidReturnOnFunctionSignature.apply`, `NoTrailingClosureParens.apply`, `PreferTrailingClosures.apply`, `WrapMultilineFunctionChains.apply`, `PreferEarlyExits.apply`, `NoFallThroughOnlyCases.apply`, `BlankLinesAfterSwitchCase.apply`, `ConsistentSwitchCaseSpacing.apply`, `SwitchCaseIndentation.apply`, plus `BlankLinesAfterGuardStatements.apply` from round 2.
- Deleted `Context.applyRewrite` and the now-empty `Sources/SwiftiomaticKit/Rewrites/{Decls,Exprs,Stmts}/` directories.
- All 3010 tests pass.
