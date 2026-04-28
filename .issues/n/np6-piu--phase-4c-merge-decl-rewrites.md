---
# np6-piu
title: 'Phase 4c: merge Decl rewrites'
status: in-progress
type: task
priority: high
created_at: 2026-04-28T15:49:40Z
updated_at: 2026-04-28T16:31:21Z
parent: ddi-wtv
blocked_by:
    - 7fp-ghy
sync:
    github:
        issue_number: "495"
        synced_at: "2026-04-28T16:43:51Z"
---

Phase 4c of `ddi-wtv` collapse plan: merge all rewrite logic that operates on declaration node types into hand-written `rewrite<NodeType>` functions in `Sources/SwiftiomaticKit/Rewrites/Decls/`.

## Node types covered (~14)

`ClassDecl`, `StructDecl`, `EnumDecl`, `ActorDecl`, `ProtocolDecl`, `ExtensionDecl`, `FunctionDecl`, `InitializerDecl`, `DeinitializerDecl`, `SubscriptDecl`, `VariableDecl`, `AccessorDecl`, `AccessorBlock`, `ImportDecl`.

## Rules to merge (~30)

Combined from Group A (ported, in `CompactStageOneRewriter+Generated.swift`) and Group B (unported). Spot-check examples:
- ACL/ModifierOrder/DocCommentsPrecedeModifiers (most decl types)
- ProtocolAccessorOrder (AccessorBlock)
- RedundantOverride, RedundantFinal, RedundantEscaping (FunctionDecl, ClassDecl)
- NoForceTry, NoForceUnwrap (FunctionDecl, ClassDecl, ImportDecl)
- WrapMultilineStatementBraces (most decl types)
- ModifiersOnSameLine (ImportDecl)
- RedundantSwiftTestingSuite (ClassDecl, ImportDecl)
- RedundantSelf (most scope-opening decls — willEnter/didExit hooks)
- PreferSelfType (Class/Struct/Enum/Actor/Extension — willEnter/didExit hooks)

Inventory the precise rule list per node type from `.build/.../CompactStageOneRewriter+Generated.swift` and the unported-rule files at the start of this work.

## Done when

- One `rewrite<NodeType>(_:context:)` function per decl node type, in its own file under `Rewrites/Decls/`.
- `CompactStageOneRewriter` dispatch updated.
- Class shells deleted for rules whose entire surface lives in decl node types.
- Full suite green (modulo rules covered in other sub-issues).

## Notes

- `willEnter`/`didExit` scope hooks (for `RedundantSelf`, `PreferSelfType`) are absorbed directly — no longer separate static functions, just inline state push/pop at the top/bottom of the rewrite function.
- Order matters where multiple rules touch the same decl: lock in alphabetical or explicit priority, document in code.
