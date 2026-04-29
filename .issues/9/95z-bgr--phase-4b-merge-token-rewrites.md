---
# 95z-bgr
title: 'Phase 4b: merge Token rewrites'
status: completed
type: task
priority: high
created_at: 2026-04-28T15:49:23Z
updated_at: 2026-04-29T01:21:14Z
parent: ddi-wtv
blocked_by:
    - 7fp-ghy
sync:
    github:
        issue_number: "503"
        synced_at: "2026-04-28T16:43:53Z"
---

Phase 4b of `ddi-wtv` collapse plan: merge all rewrite logic that operates on `TokenSyntax` into a hand-written function `rewriteToken(_:context:)` in `Sources/SwiftiomaticKit/Rewrites/Tokens/Token.swift`.

## Rules to merge (9)

**Already ported (have static transform):**
- FormatSpecialComments
- LeadingDotOperators
- RedundantBackticks
- WrapSingleLineComments

**Unported (class-only):**
- BlankLinesAroundMark
- NestedCallLayout (Token-touching portion)
- UppercaseAcronyms
- WrapMultilineFunctionChains (Token-touching portion)
- WrapMultilineStatementBraces (Token-touching portion)

## Done when

- `rewriteToken(_:context:)` exists; each rule's logic gated on `context.isRuleEnabled("<key>")`.
- `CompactStageOneRewriter.visit(_ TokenSyntax)` calls it.
- Token-only rule shells deleted; rules that span Token + other node types keep shells until those node types' phases complete (or coordinate cross-phase deletion).
- Full suite green (modulo rules covered in 4a/4c/4d/4e).

## Notes

- Trivia-sensitive: `Context.ruleState` patterns from `LeadingDotOperators` (pendingLeadingTrivia, pendingComment) need careful preservation.
- Order matters: comment formatting before backtick stripping before dot-operator handling before uppercase-acronyms (verify against legacy ordering).



## Progress (2026-04-28)

### Done

- Added `TokenSyntax` to generator's `manuallyHandledNodeTypes`. Compact rewriter now dispatches Token visits through the merged function.
- Created `Sources/SwiftiomaticKit/Rewrites/Tokens/TokenRewrites.swift` (named to avoid SwiftPM .o filename collision with `Layout/Tokens/Token.swift`) containing `rewriteToken(_:context:)`.
- Merged 6 rules covering actual Token-level work:
  - **Forwarded to existing static transforms**: FormatSpecialComments, LeadingDotOperators, RedundantBackticks, WrapSingleLineComments.
  - **Inlined as fileprivate helpers**: BlankLinesAroundMark, UppercaseAcronyms.
- Build clean (160s, 12 warnings); parity test green (0.412s).

### Out of scope (correction)

The original 4b brief listed NestedCallLayout, WrapMultilineFunctionChains, WrapMultilineStatementBraces as Token-touching. **They aren't** — their `override func visit(_ TokenSyntax)` methods belong to internal `SyntaxRewriter` helper classes (`IndentShiftRewriter`, `PeriodTriviaRewriter`, `TokenStripper`), not the rule classes themselves. These rules visit structural nodes (FunctionCall, IfExpr, etc.) and belong to 4c/4d/4e. No-op placeholders left as audit markers in TokenRewrites.swift.

### Pending in 4b (deferred to 4g)

Same as 4a: deletion of the 6 rules' `visit(_ TokenSyntax)` overrides and (for ported ones) their static `transform(_ TokenSyntax, ...)`. Defer to single legacy-removal landing in 4g.



## Note: willEnter ordering fix in 4a applies here too

See 49k-dtg for details. `rewriteToken` doesn't define any `willEnter(_ TokenSyntax, ...)` hooks (no Token-touching rule has file-level state), so this file required no edit — but the generator change applies to all manually-handled types, including TokenSyntax.



## Summary of Changes

Phase 4 merge work landed and verified through 4f's full-suite run (3012 pass / 2 unrelated). Compact pipeline is now the default; legacy `RewritePipeline` deleted in 4g. The merged `Rewrites/<Group>/<NodeType>.swift` files this issue tracked are in place and exercised by every rule test.
