---
# zvf-rsq
title: 'Phase 4d: merge Stmt rewrites'
status: completed
type: task
priority: high
created_at: 2026-04-28T15:49:54Z
updated_at: 2026-04-29T01:21:14Z
parent: ddi-wtv
blocked_by:
    - 7fp-ghy
sync:
    github:
        issue_number: "500"
        synced_at: "2026-04-28T17:19:44Z"
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



## Progress (2026-04-28)

13 stmt-related node types added to `manuallyHandledNodeTypes` and merged via per-file functions in `Sources/SwiftiomaticKit/Rewrites/Stmts/`. Each forwards to existing static transforms in alphabetical order with audit-only `shouldFormat` calls for unported rules. Build clean (17 warnings — likely unused `nodeSyntax` locals); parity test green (0.420s).

Class shells stay; deletion deferred to 4g.



## Update (2026-04-28)

Inlined unported rules into the Phase 4d merged stmt files:

- `BlankLinesAfterGuardStatements` → `Rewrites/Stmts/CodeBlock.swift` (`applyBlankLinesAfterGuardStatements`).
- `BlankLinesAfterSwitchCase` → `Rewrites/Stmts/SwitchExpr.swift` (`applyBlankLinesAfterSwitchCase`).
- `NoFallThroughOnlyCases` → `Rewrites/Stmts/SwitchCaseList.swift` (`applyNoFallThroughOnlyCases` + the merge / classification helpers).
- `PreferEarlyExits` → `Rewrites/Stmts/CodeBlockItemList.swift` (`applyPreferEarlyExits` + `codeBlockEndsWithEarlyExit`).
- `SwitchCaseIndentation` → `Rewrites/Stmts/SwitchExpr.swift` (`applySwitchCaseIndentation` + `reindentCase` + `replaceIndentation` + `lineIndentation`); reads `context.configuration[SwitchCaseIndentation.self].style` and `context.configuration[IndentationSetting.self]`.
- `NoParensAroundConditions` → new `Rewrites/Stmts/NoParensAroundConditionsHelpers.swift` with `noParensMinimalSingleExpression` and `noParensFixKeywordTrailingTrivia`; wired across `IfExpr`, `ConditionElement`, `GuardStmt`, `WhileStmt`, `RepeatStmt`, `SwitchExpr`, `ReturnStmt`, `InitializerClause` (the last lives in `Rewrites/Exprs/` but uses the same helpers).
- `BlankLinesBeforeControlFlowBlocks` → new `Rewrites/Stmts/BlankLinesBeforeControlFlowHelpers.swift` with `blankLinesBeforeControlFlowInsertBlankLines`; wired in `CodeBlock` and `SwitchCase`.

Audit-only entries remaining: `WrapMultilineStatementBraces` (16 occurrences across stmt and decl files; warrants own sub-issue).



## Summary of Changes

Phase 4 merge work landed and verified through 4f's full-suite run (3012 pass / 2 unrelated). Compact pipeline is now the default; legacy `RewritePipeline` deleted in 4g. The merged `Rewrites/<Group>/<NodeType>.swift` files this issue tracked are in place and exercised by every rule test.
