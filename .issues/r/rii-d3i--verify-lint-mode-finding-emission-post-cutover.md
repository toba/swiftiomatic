---
# rii-d3i
title: Verify lint-mode finding emission post-cutover
status: draft
type: bug
priority: high
created_at: 2026-04-29T17:20:35Z
updated_at: 2026-04-29T17:20:35Z
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
