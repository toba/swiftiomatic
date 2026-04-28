---
# mn8-do3
title: 'Phase 4e: merge Expr rewrites'
status: in-progress
type: task
priority: high
created_at: 2026-04-28T15:50:14Z
updated_at: 2026-04-28T17:18:46Z
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
