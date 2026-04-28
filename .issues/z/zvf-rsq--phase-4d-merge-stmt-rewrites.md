---
# zvf-rsq
title: 'Phase 4d: merge Stmt rewrites'
status: ready
type: task
priority: high
created_at: 2026-04-28T15:49:54Z
updated_at: 2026-04-28T15:49:54Z
parent: ddi-wtv
blocked_by:
    - 7fp-ghy
sync:
    github:
        issue_number: "500"
        synced_at: "2026-04-28T16:43:51Z"
---

Phase 4d of `ddi-wtv` collapse plan: merge all rewrite logic that operates on statement node types into hand-written `rewrite<NodeType>` functions in `Sources/SwiftiomaticKit/Rewrites/Stmts/`.

## Node types covered (~12)

`IfExpr`, `GuardStmt`, `ForStmt`, `WhileStmt`, `RepeatStmt`, `DoStmt`, `SwitchExpr`, `SwitchCase`, `SwitchCaseList`, `ReturnStmt`, `CodeBlock`, `CodeBlockItemList`, `ConditionElement`.

## Rules to merge (~15)

Combined from Group A (ported) and Group B (unported). Includes:
- WrapSingleLineBodies (most stmt types)
- WrapMultilineStatementBraces (If/Guard/For/While/Do/Switch)
- BlankLinesBeforeControlFlowBlocks
- BlankLinesAfterSwitchCase
- BlankLinesAfterGuardStatements
- PreferEarlyExits (Guard)
- NoParensAroundConditions (If/Guard/While/etc)
- SwitchCaseIndentation
- NoFallThroughOnlyCases (SwitchCase)
- NoSemicolons (CodeBlockItemList, MemberBlockItemList)
- OneDeclarationPerLine (CodeBlockItemList)
- NoAssignmentInExpressions (CodeBlockItemList)
- RedundantReturn (ReturnStmt-adjacent)

Inventory exact list at start of work.

## Done when

- One `rewrite<NodeType>(_:context:)` function per stmt node type.
- `CompactStageOneRewriter` dispatch updated.
- Class shells deleted for rules whose entire surface lives in stmt node types.
- Full suite green (modulo rules covered in other sub-issues).

## Notes

- `WrapSingleLineBodies` had Phase 1 divergences flagged (lacks instance `currentIndent`/`chainBaseIndent` — see `7fp-ghy` notes). Resolve here by maintaining indent state via local variables in the merged function (no class instance state needed; everything threads through the function args + Context).
