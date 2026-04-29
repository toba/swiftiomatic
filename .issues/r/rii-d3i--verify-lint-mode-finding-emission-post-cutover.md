---
# rii-d3i
title: Verify lint-mode finding emission post-cutover
status: completed
type: bug
priority: high
created_at: 2026-04-29T17:20:35Z
updated_at: 2026-04-29T17:57:55Z
parent: ddi-wtv
sync:
    github:
        issue_number: "506"
        synced_at: "2026-04-29T17:25:06Z"
---

After the `ddi-wtv` cutover and the dead-shell strip passes, most rewrite rules no longer have an instance `override func visit(_:)`. Their finding emission lives in `static willEnter`/`static transform` invoked by the compact pipeline.

The `LintCoordinator` (used by `sm lint`) only walks `LintPipeline`, whose generated dispatcher (`Sources/SwiftiomaticKit/Generated/Pipelines+Generated.swift`) reads from `RuleCollector.syntaxNodeLinters` — populated only by rules with instance `visit` overrides. After the strip:

- Rewrite rules with no `visit` override: not in dispatcher → no findings emitted in `sm lint` mode.
- Rewrite rules with `visit` override (PreferShorthandTypeNames + 10 structural-pass): still dispatched.
- Lint-only rules (`SyntaxLintRule` subclasses): unaffected, still dispatched correctly.

## Investigation

1. Confirm the regression exists by running `sm lint` on a file with known violations of, say, `RedundantSelf` or `NoSemicolons` (both fully ported to compact pipeline). Verify findings are/aren't emitted.
2. If confirmed, design a fix:
   - Option A: `LintCoordinator` runs the compact rewriter and discards the output, collecting findings.
   - Option B: Generate a parallel lint dispatcher that calls each rule's static `willEnter` (where findings are emitted pre-recursion) — sidesteps re-running the rewrite.
   - Option C: Hybrid — `LintPipeline` keeps lint-only rules; rewrite-rule findings come from a one-shot rewriter pass.
3. Decide whether `assertLinting` (currently unused in tests) should be re-enabled to catch this class of regression.

## Why high priority

`sm lint` is one of the three CLI surfaces (alongside `sm format` and `sm analyze`). If it under-reports findings for the majority of rules, that's a user-visible feature regression.



## Summary of Changes

**Bug confirmed:** `sm lint /tmp/test_lint.swift` (containing `import Foundation;`, multiple `;` violations, `var x: String = "hello"`, and `self.x`) emitted only one finding (`afterImports` from `BlankLinesAfterImports`). Expected violations of `noSemicolons`, `redundantType`, `redundantSelf` were silently dropped.

**Fix (Option A):** `Sources/SwiftiomaticKit/Syntax/Linter/LintCoordinator.swift::lint(syntax:operatorTable:assumingFileURL:source:)` now runs `CompactStageOneRewriter(context: context).rewrite(Syntax(syntax))` and discards the result before walking `LintPipeline`. This drives every compact-pipeline rule's `static willEnter`/`static transform` finding-emission path. Lint-only (`SyntaxLintRule`) and structural-pass rules continue to fire via the existing LintPipeline dispatch.

**Secondary fix:** Stripped the now-redundant instance `diagnose` calls from `PreferShorthandTypeNames.visit(_:IdentifierTypeSyntax)` and `visit(_:GenericSpecializationExprSyntax)`. After the LintCoordinator fix the static `willEnter` overloads emit findings in both lint and rewrite modes; the instance-side calls (gated on `compactPipelineParent == nil`) caused double emission in lint mode. The `compactPipelineParent` property itself is still used for parent fallback during recursive visits and stays.

### Verification

- `sm lint /tmp/test_lint.swift` now emits `noSemicolons` (×3), `redundantType`, `redundantSelf`, plus the previously-emitted `afterImports`.
- `sm lint /tmp/test_shorthand.swift` emits exactly 3 `preferShorthandTypeNames` findings (was 6 — double-emission gone).
- `xc-swift swift_diagnostics --no-include-lint`: build clean, 13 warnings (unchanged baseline).
- `xc-swift swift_package_test`: 3012 pass / 2 pre-existing `Layout/GuardStmtTests` pretty-printer-idempotency failures.

### Follow-up

- `assertLinting` test helper enablement (item 3 of original investigation list) deferred. Adding it as a follow-up would catch this class of regression early but isn't strictly required to close this bug.
- The `compactPipelineParent` property on `PreferShorthandTypeNames` could potentially be removed if the rule is fully ported out of the fresh-instance pattern (issue `2tv-v3y`), but is correct as-is.
