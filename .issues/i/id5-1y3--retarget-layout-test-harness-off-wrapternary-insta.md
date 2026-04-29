---
# id5-1y3
title: Retarget layout test harness off WrapTernary instance override
status: completed
type: task
priority: normal
created_at: 2026-04-29T17:07:37Z
updated_at: 2026-04-29T17:13:20Z
parent: dal-dmw
sync:
    github:
        issue_number: "507"
        synced_at: "2026-04-29T17:25:07Z"
---

The layout test harness in `Tests/SwiftiomaticTests/Layout/LayoutTestCase.swift` invokes `WrapTernary(context: context).rewrite(...)` directly. This is the only thing keeping `WrapTernary.override func visit(_ TernaryExprSyntax)` alive in the rule file (per session 20 note on `ddi-wtv`).

Plan: replace the direct rewrite invocation with a small inline `SyntaxRewriter` (or reuse infrastructure) that walks ternaries and applies `WrapTernary.transform` post-recursion. Then strip the instance `override func visit` from the rule.

Verify: full suite green, layout tests still pass. Pre-existing 2 GuardStmt idempotency failures are out of scope.



## Summary of Changes

### Files

- **`Tests/SwiftiomaticTests/Layout/LayoutTestCase.swift`** — replaced `WrapTernary(context: context).rewrite(...)` with a private `WrapTernaryHarnessRewriter: SyntaxRewriter` that mirrors the compact pipeline's call shape (`super.visit` then `WrapTernary.transform`).
- **`Sources/SwiftiomaticKit/Rules/Wrap/WrapTernary.swift`** — stripped `override func visit(_ TernaryExprSyntax)` (the static `transform` is the source of truth; the harness now drives recursion via the test-side rewriter).

### Verification

- `xc-swift swift_diagnostics --no-include-lint` — Build succeeded, 13 warnings (unchanged baseline).
- Layout|WrapTernary filter: **31 pass**, all green.
- Full suite: **3012 pass, 2 fail** (the 2 pre-existing `Layout/GuardStmtTests` pretty-printer-idempotency failures, unrelated).

`override func visit` total in `Sources/SwiftiomaticKit/Rules/`: **197** (down from 198 at session start). One last `RewriteSyntaxRule` instance override gone.
