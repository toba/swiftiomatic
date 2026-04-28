---
# mn8-do3
title: 'Phase 4e: merge Expr rewrites'
status: in-progress
type: task
priority: high
created_at: 2026-04-28T15:50:14Z
updated_at: 2026-04-28T20:03:13Z
parent: ddi-wtv
blocked_by:
    - 7fp-ghy
sync:
    github:
        issue_number: "499"
        synced_at: "2026-04-28T17:19:44Z"
---

Phase 4e of `ddi-wtv` collapse plan: merge all rewrite logic that operates on expression node types into hand-written `rewrite<NodeType>` functions in `Sources/SwiftiomaticKit/Rewrites/Exprs/`.

## Node types covered (~14)

`ClosureExpr`, `ClosureSignature`, `FunctionCallExpr`, `MemberAccessExpr`, `SubscriptCallExpr`, `TernaryExpr`, `InfixOperatorExpr`, `PrefixOperatorExpr`, `AsExpr`, `IsExpr`, `TryExpr`, `StringLiteralExpr`, `IdentifierType`, `FunctionType`, `FunctionSignature`, `ForceUnwrapExpr`, `GenericSpecializationExpr`, `DeclReferenceExpr`, `InitializerClause`.

## Rules to merge (~20)

Combined from Group A (ported) and Group B (unported). Includes:
- RedundantSelf (MemberAccessExpr — willEnter/didExit on ClosureExpr)
- PreferSelfType (MemberAccessExpr)
- NoVoidTernary (TernaryExpr)
- NoAssignmentInExpressions (InfixOperatorExpr)
- PreferExplicitFalse (PrefixOperatorExpr)
- UnusedArguments (ClosureExpr)
- NoForceCast (AsExpr)
- NoForceTry (TryExpr)
- NoForceUnwrap (11 node types touched)
- PreferShorthandTypeNames (IdentifierType, FunctionType, etc)
- PreferVoidReturn, NoVoidReturnOnFunctionSignature (FunctionSignature)
- PreferAnyObject (IdentifierType, ProtocolDecl conformances)
- NoTrailingClosureParens (FunctionCallExpr)
- PreferTrailingClosures (FunctionCallExpr)
- NamedClosureParams (ClosureExpr)
- NestedCallLayout (FunctionCallExpr)
- WrapMultilineFunctionChains (FunctionCallExpr)
- StrongOutlets (VariableDecl/AttributedSyntax — borderline; place where it fits)

Inventory exact list at start of work.

## Done when

- One `rewrite<NodeType>(_:context:)` function per expr node type.
- `CompactStageOneRewriter` dispatch updated.
- Class shells deleted for rules whose entire surface lives in expr node types.
- Full suite green (modulo rules covered in other sub-issues).

## Notes

- Several Group B rules touch many node types (`NoForceUnwrap`: 11 types). Their logic distributes across multiple files in this phase — coordinate so each fragment is gated on the same `isRuleEnabled("<key>")` and findings still emit with consistent category.
- `RedundantSelf` and `PreferSelfType` MemberAccessExpr logic depends on willEnter/didExit hooks established in 4c (decl scopes). Coordinate ordering: 4c can land first, OR both rules' logic lands at the boundary of 4c+4e.



## Progress (2026-04-28)

19 expr/type node types added to `manuallyHandledNodeTypes` and merged via per-file functions in `Sources/SwiftiomaticKit/Rewrites/Exprs/`. Each forwards to existing static transforms in alphabetical order with audit-only `shouldFormat` calls for unported rules. Build clean (30 warnings — unused locals in stub functions); parity test green (0.406s).

Empty merge files (no transforms registered, only generator-emitted hooks if any): `InitializerClause.swift`, `IsExpr.swift`.

Class shells stay; deletion deferred to 4g.



## Update (2026-04-28)

Inlined unported rules into the Phase 4e merged expr files:

- `NoForceCast` → `Rewrites/Exprs/AsExpr.swift` (lint-only diagnostic for `as!`).
- `NoVoidReturnOnFunctionSignature` → `Rewrites/Exprs/FunctionSignature.swift` (`applyNoVoidReturnOnFunctionSignature`).
- `NoTrailingClosureParens` → `Rewrites/Exprs/FunctionCallExpr.swift` (`applyNoTrailingClosureParens`). Dropped the rule's manual `rewrite(...)` re-recursion — children already visited by the generator.
- `PreferVoidReturn` → `Rewrites/Exprs/FunctionType.swift` and `Rewrites/Exprs/ClosureSignature.swift`. Shared helpers `hasNonWhitespaceTrivia` and `makeVoidIdentifierType` are internal-level (no `fileprivate`) functions in `FunctionType.swift` and reused from `ClosureSignature.swift`.
- `NoParensAroundConditions` (InitializerClause site) → `Rewrites/Exprs/InitializerClause.swift` calling shared helpers from `Rewrites/Stmts/NoParensAroundConditionsHelpers.swift`.
- `PreferTrailingClosures` → `Rewrites/Exprs/FunctionCallExpr.swift` (`applyPreferTrailingClosures` + `preferTrailingClosuresConvertSingle`/`...ConvertMultiple` + helpers `functionName`/`isInConditionalContext`).
- `NamedClosureParams` → new `Rewrites/Exprs/NamedClosureParamsHelpers.swift` with reference-typed `NamedClosureParamsState` (`[Bool]` stack of `insideMultilineClosure` flags). Static `willEnter`/`didExit` on `NamedClosureParams` for `ClosureExprSyntax` push/pop the flag; `rewriteDeclReferenceExpr` calls `namedClosureParamsRewriteDeclReference` to diagnose `\$N`.
- `NoForceTry` (TryExpr + ClosureExpr willEnter/didExit) → new `Rewrites/Exprs/NoForceTryHelpers.swift` with `NoForceTryState` on `Context.ruleState` (`importsTesting`, `insideXCTestCase`, `insideTestFunction`, `convertedForceTry`, `functionDepth`, `closureDepth`). Static `willEnter`/`didExit` on `NoForceTry` for `ClassDeclSyntax`, `FunctionDeclSyntax`, `ClosureExprSyntax`. `rewriteTryExpr` calls `noForceTryRewriteTryExpr` to diagnose / strip `!` based on scope state.

Audit-only entries remaining: `NoForceUnwrap` (11 occurrences; same shape as `NoForceTry` plus chain-top wrapping logic — ~470 lines), `NestedCallLayout` (740 lines), `WrapMultilineFunctionChains` (212 lines), `PreferShorthandTypeNames` (~640 lines, recommend porting as static `transform` rather than inlining).



### WrapMultilineFunctionChains inlined (2026-04-28)

- `WrapMultilineFunctionChains` → `Rewrites/Exprs/FunctionCallExpr.swift` (`applyWrapMultilineFunctionChains` + private helpers `wrapMultilineChainsCollect`, `wrapMultilineChainsIsInnerChainCall`, `wrapMultilineChainsIsClosingScope`, `wrapMultilineChainsIsTypeAccess`, and a private `WrapMultilineChainsPeriodTriviaRewriter` SyntaxRewriter for the per-period trivia replacement). The legacy rule's bare `PeriodTriviaRewriter` was renamed to avoid name collisions and kept private to the file.
- TokenRewrites.swift audit-only entry replaced with a pointer to the new home.



## Update (2026-04-28) — NoForceUnwrap inlined

 ported to the compact pipeline following the proven `NoForceTry` shape, with chain-top wrapping logic added on top.

- New: `Rewrites/Exprs/NoForceUnwrapHelpers.swift` with `NoForceUnwrapState` on `Context.ruleState` (test detection flags, function/closure/string-interp depth counters, plus per-chain-node save stacks for `chainNeedsWrapping`, `chainTopStack`, `chainContextStack`, `memberHadForceCastStack`).
- Static `willEnter`/`didExit` overloads on `NoForceUnwrap` for `ClassDecl`, `FunctionDecl`, `ClosureExpr`, `StringLiteralExpr`, `MemberAccessExpr`, `FunctionCallExpr`, `SubscriptCallExpr`, `ForceUnwrapExpr`, `AsExpr`. The pre-recursion node is captured in willEnter (where parent links are intact), classified for chain-top context, and stashed on stacks; rewrite functions read `.last` and didExit pops + propagates `chainNeedsWrapping` upward.
- Wired in: `SourceFile` (importsXCTest pre-scan), `ImportDecl` (importsTesting), `FunctionDecl` (post-process — adds `throws`), `ClassDecl`/`ClosureExpr`/`StringLiteralExpr` (scope-only, hooks emitted by generator).
- **Return-type change for chain-top wrapping**: `rewriteForceUnwrapExpr`, `rewriteAsExpr`, `rewriteMemberAccessExpr`, `rewriteFunctionCallExpr`, `rewriteSubscriptCallExpr` now return `ExprSyntax` (was concrete) so wrapping in `try XCTUnwrap(...)` / `try #require(...)` can change node shape. The generator's manually-handled emission already wraps the call in `ExprSyntax(...)` so no generator change was needed.

Verification: build clean (19 warnings, down from 30); `CompactPipelineParityTests` green; all 28 `NoForceUnwrapTests` green.

Audit-only counts (after this work): `WrapMultilineStatementBraces` 16, `PreferShorthandTypeNames` 2, `NestedCallLayout` 2, `RedundantEscaping` 2, `RedundantOverride` 1.



## Update (2026-04-28) — PreferShorthandTypeNames, NestedCallLayout, RedundantEscaping inlined

Generator + signature changes:
- `CompactStageOneRewriterGenerator` now passes `parent: Syntax?` (captured before `super.visit`) to all manually-handled `rewrite<NodeType>` functions, matching the existing parent-aware contract for non-manually-handled types.
- All 47 `rewrite<NodeType>` functions updated to accept `parent: Syntax?` and forward it to `<RuleType>.transform(node, parent: parent, context:)` calls.
- 5 chain-eligible expr functions (`ForceUnwrap`, `AsExpr`, `MemberAccess`, `FunctionCall`, `SubscriptCall`) return `ExprSyntax` (was concrete) so chain-top wrapping can change node shape; `IdentifierType`/`GenericSpecializationExpr` updated likewise for `PreferShorthandTypeNames` (`Array<Foo>` → `[Foo]` etc).

Static transforms added (fresh-instance forwarding pattern — wraps the existing rule's `visit(_:)` in a temporary instance):
- `PreferShorthandTypeNames.transform(_ IdentifierType, ...)` and `transform(_ GenericSpecializationExpr, ...)` — wired in `Rewrites/Exprs/IdentifierType.swift` + `GenericSpecializationExpr.swift`.
- `NestedCallLayout.transform(_ FunctionCallExpr, ...)` — wired in `Rewrites/Exprs/FunctionCallExpr.swift` (runs before NoForceUnwrap chain wrapping).
- `RedundantEscaping.transform(_ FunctionDecl, ...)` and `transform(_ InitializerDecl, ...)` — wired in `Rewrites/Decls/FunctionDecl.swift` + `InitializerDecl.swift`.

The fresh-instance pattern is suitable when the rule has no scope-bearing instance state and its `visit(_:)` recursive descent is idempotent on already-rewritten children (visiting an `ArrayType` is a no-op for `PreferShorthandTypeNames`).

Verification: build clean (13 warnings, was 30); `CompactPipelineParityTests` green; 77 targeted tests pass (parity + NoForceUnwrap + NestedCallLayout + PreferShorthandTypeNames + RedundantEscaping).

Audit-only counts (after this work): `WrapMultilineStatementBraces` 16, `NestedCallLayout` 1 (Token-level no-op marker only), `RedundantOverride` 1.



## Update (2026-04-28) — WrapMultilineStatementBraces, RedundantOverride inlined

- **WrapMultilineStatementBraces** (371 lines): added 15 static `transform` overloads on the rule (one per visited node type: `IfExpr`, `GuardStmt`, `ForStmt`, `WhileStmt`, `DoStmt`, `SwitchExpr`, `FunctionDecl`, `InitializerDecl`, `DeinitializerDecl`, `ClassDecl`, `StructDecl`, `EnumDecl`, `ActorDecl`, `ProtocolDecl`, `ExtensionDecl`). Same fresh-instance forwarding pattern. Wired into all 16 audit sites in one pass.
- **RedundantOverride** (153 lines): added `transform(_ FunctionDecl, ...)`. Required changing `rewriteFunctionDecl` return type from `FunctionDeclSyntax` to `DeclSyntax` to allow returning the empty/missing decl that signals removal.

Verification: build clean (12 warnings); parity test green; 28 targeted tests pass (RedundantOverride + WrapMultilineStatementBraces + parity).

**All 4 previously-unported rules are now inlined. Audit-only count: 16 → 0** real entries (2 token-level no-op markers remain by design — `NestedCallLayout` and `WrapMultilineStatementBraces` placeholders in `Rewrites/Tokens/TokenRewrites.swift` since these rules transform structural nodes, not tokens; the markers preserve rule-mask gating semantics).
