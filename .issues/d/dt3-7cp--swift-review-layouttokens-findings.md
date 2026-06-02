---
# dt3-7cp
title: 'Swift review: Layout/Tokens findings'
status: completed
type: task
priority: normal
created_at: 2026-06-02T01:15:49Z
updated_at: 2026-06-02T01:25:29Z
sync:
    github:
        issue_number: "715"
        synced_at: "2026-06-02T01:51:58Z"
---

Swift review findings for `Sources/SwiftiomaticKit/Layout/Tokens/` (18 files, ~6000 lines).

## High

- [ ] **Force unwrap on potentially-empty trivia** — `CommentMovingRewriter.swift:75` does `operatorTrailing.pieces.last!`. Line 74 checks `hasLineComment` but does not guarantee non-empty `pieces`. Replace with `guard let last = operatorTrailing.pieces.last else { ... }`.
- [ ] **Force unwrap on cast** — `CommentMovingRewriter.swift:60` does `super.visit(node).as(InfixOperatorExprSyntax.self)!`. Replace with a safe cast and fallback to `super.visit(node)`.
- [ ] **Lint warnings outstanding** — `TokenStream+Collections.swift:311` and `:313` flagged by `wrapTernaryBranches`; wrap branches onto new lines.

## Medium

- [ ] **Duplicated parenthesized break-arrangement pattern** — `TokenStream+Helpers.swift:120–125`, `TokenStream+Closures.swift:307–319`, `TokenStream+Collections.swift:280–313` all repeat the `.break(.open, size: 0), .open(...)` / `.break(.close(...), size: 0), .close` pair. Extract a shared helper (e.g. `arrangeParenthesizedBreaks`) to keep break semantics uniform.
- [ ] **Redundant identical init in both branches** — `TokenStream+Collections.swift:310–312` initializes `openNewlines` and `closeNewlines` with the same expression on both ternary branches. Collapse to a single `let`.
- [ ] **Hot-path allocation churn in `appendToken`** — `TokenStream+Appending.swift:226–304` rewrites the last token (`tokens[tokens.count - 1] = .comment(...)`) when merging comments, scanning backward through tokens on every visit. Consider deferring comment merging to a post-processing pass or caching the previous-token kind to skip the scan.
- [ ] **Trivia partitioning re-iterates** — `TokenStream+Helpers.swift:415–418` `partitionTrailingTrivia` walks trivia twice (find pivot, then slice). Return the pivot index from the search and slice once.

## Low

- [ ] **Naming inconsistency for labeled-expression arrangement** — `TokenStream+Collections.swift:69` (`arrangeAsTupleExprElement`) vs `:359` (`arrangeAsFunctionCallArgument`) do effectively the same thing. Consider unifying as `arrangeLabeledExpression(context:)`.
- [ ] **Magic alignment numbers** — `TokenStream+ControlFlow.swift:71, 228` use `.alignment(spaces: 3/5/6)` inline. Pull into named constants documenting which keyword/structure they align to.

## Notes

- Found no `Any` / `AnyObject` usage to eliminate; no callback-based async to modernize; no XCTest in this dir; no obvious typed-throws candidates.
- Performance items above are speculative without profiling — confirm via `LayoutCoordinator(printTokenStream:)` traces or Instruments before reworking.


## Summary of Changes

**High (all done)**
- `CommentMovingRewriter.swift:60` — replaced `super.visit(node).as(...)!` with safe `guard let` fallback to `visited`.
- `CommentMovingRewriter.swift:75` — replaced `operatorTrailing.pieces.last!` with `if let lastPiece = ...`.
- `TokenStream+Collections.swift:311,313` — wrapped ternary branches; resolved `wrapTernaryBranches`.

**Medium**
- Collapsed identical `openNewlines`/`closeNewlines` ternaries into a single `newlines` binding in `TokenStream+Collections.swift`.
- Added `arrangeBlockBreaks(left:right:)` helper to `TokenStream+Helpers.swift`; refactored 6 identical call sites in `TokenStream+Closures.swift`, `TokenStream+Collections.swift`, `TokenStream+TypesAndPatterns.swift`.
- **Skipped** the `appendToken` comment-merge backscan rework — the linear `lastIndex(where:)` only runs on the rare merge path, and the speculative optimization wasn't worth the regression risk without a profile to justify it.
- **Skipped** the `partitionTrailingTrivia` rework — re-read confirmed it is already a single pass (`firstIndex` + slicing); review claim was incorrect.

**Low**
- Extracted `ifConditionAlignment` (3), `whileConditionAlignment` (6), `caseItemAlignment` (5) as named file-private constants in `TokenStream+ControlFlow.swift`.
- **Skipped** renaming `arrangeAsTupleExprElement` / `arrangeAsFunctionCallArgument` — the two helpers have meaningfully different bodies; the names accurately reflect their context.

**Verification**
- `sm lint` clean on all touched files.
- Build succeeded.
- Full test suite: 3414 passed, 0 failed.
