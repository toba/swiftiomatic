---
# wts-z1t
title: Assignment '=' break fires for member chain with trailing closures
status: completed
type: bug
priority: normal
created_at: 2026-05-08T06:33:59Z
updated_at: 2026-05-08T14:15:08Z
---

## Repro

Input:
\`\`\`swift
func foo() {
    let location = try Citation
        .join(CitationGroup.all) { \$0.groupID.eq(\$1.id) }
        .where { c, _ in c.id.eq(#bind(citationID)) }
        .select { c, g in (c.referenceID, g.projectID) }
        .fetchOne(db)
}
\`\`\`

Actual output (\`sm format\`):
\`\`\`swift
let location =
    try Citation
    .join(CitationGroup.all) { \$0.groupID.eq(\$1.id) }
    .where { c, _ in c.id.eq(#bind(citationID)) }
    .select { c, g in (c.referenceID, g.projectID) }
    .fetchOne(db)
\`\`\`

Expected (input is already correct — should be idempotent):
\`\`\`swift
let location = try Citation
    .join(CitationGroup.all) { \$0.groupID.eq(\$1.id) }
    .where { c, _ in c.id.eq(#bind(citationID)) }
    .select { c, g in (c.referenceID, g.projectID) }
    .fetchOne(db)
\`\`\`

Per documented break precedence, the chain \`.\` (rank 2) must beat the \`=\` break (rank 4). Today both fire, splitting the binding name from \`try\` and pushing the head of the chain (\`Citation\`) onto its own line.

## Reproduces without \`try\`

Same wrong wrap occurs without the \`try\` keyword — so it's not a \`KeywordModifiedExpr\` wrapping issue. Removing the trailing closures eliminates the bug, so trailing closures specifically are perturbing the chunk computation for the \`=\` break.

## Existing passing regression

\`Tests/SwiftiomaticTests/Layout/AssignmentExprTests.swift::assignmentWithTryPrefixedChainRHS\` covers a \`try chain.method()...\` RHS without trailing closures and passes. The new failure mode is specifically chains where each step has a trailing closure.

## Investigation notes

- \`visitPatternBinding\` (\`TokenStream+Bindings.swift:46\`) takes the \`rhsHasInnerBreaks\` path for \`FunctionCallExprSyntax\` RHS (no \`try\`) and the \`arrangeAssignmentBreaks\` path for \`TryExprSyntax\` RHS (because \`TryExprSyntax\` isn't in the \`rhsHasInnerBreaks\` whitelist). Both paths fail equally.
- \`visitFunctionCallExpr\` (\`TokenStream+Collections.swift:161\`) wraps \`Citation.join\` in \`.open/.close\` because \`isInOuterChain\` is gated on \`trailingClosure == nil\` (line 193). Removing that gate is what \`assignmentWithTryPrefixedChainRHS\` regression already documents — the comment says trailing-closure chains intentionally prefer breaking inside closures, but for THIS pattern (closure short, fits inline) we should still get chain-break precedence.
- The contextual break before each subsequent \`.\` is emitted by \`insertContextualBreaks\` (\`TokenStream+Breaks.swift:75\`); shouldGroup wraps the chain in \`.open/.close\` from the period through the call's \`lastToken\` (which IS the trailing closure's rightBrace) — so the closure body IS inside the group.

Likely root cause: the \`.break(.same, .elective(ignoresDiscretionary: true))\` emitted before each trailing-closure \`leftBrace\` (\`TokenStream+Collections.swift:233-236\`) is at the outer group level and inflates the \`=\` break's chunk-length so the printer commits to the \`=\` break before realizing the chain breaks would fit.

## TODO

- [ ] Add failing regression test \`assignmentWithChainOfTrailingClosureCalls\` in \`AssignmentExprTests.swift\`
- [ ] Confirm root cause by dumping token stream (set \`printTokenStream: true\` in \`LayoutCoordinator\` for the test)
- [ ] Fix in \`visitFunctionCallExpr\` or \`arrangeAssignmentBreaks\` so the \`=\` break's chunk is bounded by the next chain dot
- [ ] Verify \`assignmentWithTryPrefixedChainRHS\` and other chain-precedence tests still pass



## Status (paused mid-session)

**Both fixes implemented and Layout tests pass (144/144).** Remaining: full test suite, manual retest with release `sm`, commit.

### Diagnosis confirmed

Dumped token stream via temporary `SM_DUMP_TOKENS_FILE` instrumentation (now reverted). Root cause: source-discretionary newlines at chain dots become `.break(.contextual, .soft(discretionary: true, maxBlankLines: 0))`. Soft (non-elective) breaks bump `total += maxLineLength` per `LayoutCoordinator.swift:715` (upstream comment: "Use `maxLineLength` to ensure enclosing groups are large enough to force preceding breaks to fire"). When the `=` break is finalized at the next break at its depth, the inflated `total` includes that +100 bump, so its computed chunk-length is ~119 instead of the natural ~18. Engine sees "doesn't fit", `=` fires alongside the chain breaks.

Key insight: the `=` break must be **popped/finalized BEFORE the soft chain break is processed** (length calc at `LayoutCoordinator.swift:682-716` does pop+push of the new break, then bumps total). That requires the keyword-modifier `.open/.close` group around the chain head to close BEFORE the first contextual chain break.

### Fixes applied

1. **`try`/`await`/`unsafe` chain RHS** — `Sources/SwiftiomaticKit/Layout/Tokens/TokenStream+TypesAndPatterns.swift:209-232` (`connectingTokenForKeywordModifiedExpr`): when the chain head's FunctionCall parent is the base of an outer `MemberAccessExpr` (multi-step chain), return `base.lastToken` (e.g. `Citation`) instead of `declName.baseName.lastToken` (e.g. `join`). The visitTryExpr `.close` then lands after `Citation`, before the soft chain break at `.join`, so `=` is popped at that break with un-bumped `total`.

2. **Non-`try` chain RHS** — `Sources/SwiftiomaticKit/Layout/Tokens/TokenStream+Collections.swift:213-228` (`visitFunctionCallExpr`, `else if !isKeywordModified` branch): mirror fix. When `isPartOfOuterMemberAccessChain(node)` is true, place `.close` after `base.lastToken` instead of after `calledMemberAccessExpr.declName.baseName.lastToken`.

Both fixes are gated on "call is the head of a multi-step chain" so single-step `try base.method()` / `base.method()` keep their current grouping (anchor at declName).

### Tests

- [x] `assignmentWithChainOfTrailingClosureCalls` — try-prefixed multi-line input — PASSES.
- [x] `assignmentWithChainOfTrailingClosureCallsNoTry` — same chain without `try` — PASSES.
- [x] Existing `assignmentWithTryPrefixedChainRHS` (single-line input, line length 55) — PASSES.
- [x] Full Layout suite (144 tests) — PASSES.
- [ ] Full test suite (~3000 tests) — NOT YET RUN.
- [ ] Manual retest with installed `sm` via release build.

### To resume

1. `swift_package_test` with no filter to catch any non-Layout regressions.
2. `swift_package_build product=sm configuration=release` then `/opt/homebrew/bin/sm format /tmp/repro.swift` (or copy to Cellar) for manual sanity check.
3. Commit. Suggested message: `fix wrap of '=' before member-access chain RHS with discretionary newlines (issue wts-z1t)`.

### Files touched (mine only — there are unrelated edits in working tree from other agents)

- `Sources/SwiftiomaticKit/Layout/Tokens/TokenStream+TypesAndPatterns.swift` — `connectingTokenForKeywordModifiedExpr` anchor change. Affects visitTryExpr / visitAwaitExpr / visitUnsafeExpr (all use this helper).
- `Sources/SwiftiomaticKit/Layout/Tokens/TokenStream+Collections.swift` — `visitFunctionCallExpr` `.close` placement in the `!isKeywordModified` branch.
- `Tests/SwiftiomaticTests/Layout/AssignmentExprTests.swift` — added `assignmentWithChainOfTrailingClosureCalls` (around line 258) and `assignmentWithChainOfTrailingClosureCallsNoTry` (around line 287).

The `SM_DUMP_TOKENS_FILE` env-var instrumentation in `LayoutCoordinator.swift` was reverted at end of session — the file is back to its pre-debug state.



## Summary of Changes

Fixed the wrap of `=` before a member-access chain RHS whose steps each take a trailing closure (e.g. SQL builder DSL). The `=` break was firing alongside chain breaks because a discretionary newline at the first chain dot becomes a `.soft(discretionary:)` break that bumps `total` by `maxLineLength`, inflating the chunk-length of the enclosing `=` break.

### Fix

Two sites place `.close` after the chain head; both now retarget the close from after `<name>` to after the chain base when `shouldRetargetChainHeadCloseForAssignmentRHS(_ call:)` returns true:

- `Sources/SwiftiomaticKit/Layout/Tokens/TokenStream+TypesAndPatterns.swift` — `connectingTokenForKeywordModifiedExpr` (covers `try`/`await`/`unsafe`).
- `Sources/SwiftiomaticKit/Layout/Tokens/TokenStream+Collections.swift` — `visitFunctionCallExpr` non-keyword path.

### Gate

`shouldRetargetChainHeadCloseForAssignmentRHS` (added to `TokenStream+Appending.swift`) requires:
1. Head call has a trailing closure.
2. Head's trailing closure is single-line in source (multi-line head closures keep the legacy `=`-breaks-with-grouped-head layout — preserves `chainedTrailingClosureMethods`).
3. Source has a discretionary newline at the next chain dot (only then does the soft-break inflation happen — preserves `tryKeywordBreaking` / `awaitKeywordBreaking` / `tryAwaitKeywordBreaking` which want `=` to fire alongside chain breaks for non-trailing-closure chains).
4. Walking up the chain (through transparent postfix wrappers and `try`/`await`/`unsafe`), the chain's enclosing expression is the RHS of an `InitializerClause` (i.e., `PatternBinding`) or an `InfixOperator` whose operator is `=` (preserves `methodChainingWithClosuresFullWrap` which is a non-assignment chain).

### Tests

- New: `assignmentWithChainOfTrailingClosureCalls`, `assignmentWithChainOfTrailingClosureCallsNoTry` in `AssignmentExprTests.swift`.
- Full suite: 3261 passed, 0 failed.
