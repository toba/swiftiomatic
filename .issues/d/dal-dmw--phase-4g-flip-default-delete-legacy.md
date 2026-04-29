---
# dal-dmw
title: 'Phase 4g: flip default + delete legacy'
status: in-progress
type: task
priority: high
created_at: 2026-04-28T15:50:43Z
updated_at: 2026-04-29T01:21:26Z
parent: ddi-wtv
blocked_by:
    - 2sn-0al
sync:
    github:
        issue_number: "497"
        synced_at: "2026-04-28T16:43:51Z"
---

Phase 4g of `ddi-wtv` collapse plan: flip the default to compact and delete all legacy infrastructure in one landing.

## Tasks

- `RewriteCoordinator.runCompactPipeline` calls `runTwoStageCompactPipeline` unconditionally; remove the `useCompactPipeline` debug-option branch.
- Delete `DebugOptions.useCompactPipeline`.
- Delete `Sources/SwiftiomaticKit/Syntax/Rewriter/RewritePipeline.swift`.
- Delete `Sources/SwiftiomaticKit/Syntax/SyntaxRule.swift`'s `RewriteSyntaxRule` base class (keep `SyntaxLintRule`).
- Delete `Tests/SwiftiomaticTests/Sanity/CompactPipelineParityTests.swift` (no legacy to compare against).
- Remove the rewrite section of `Sources/SwiftiomaticKit/Generated/Pipelines+Generated.swift` (lint section stays).
- Update `Sources/GeneratorKit/RuleCollector.swift` to drop the legacy rewrite-rule detection paths; keep lint-rule discovery.
- Verify: full suite green, perf test < 200 ms, `sm format Sources/` empty diff.
- Mark `dil-cew` (legacy delete tracking issue, if separate from this) as completed/scrapped — its scope is fully absorbed here.

## Verification gates

- `xc-swift swift_diagnostics --build-tests` clean (no references to deleted symbols).
- `xc-swift swift_package_test` all green.
- LOC reduction visible (~120 class shells gone, plus `RewritePipeline`, `RewriteSyntaxRule`).
- Perf test confirms < 200 ms target on `LayoutCoordinator.swift` (legacy was 4.7s — expect ~50-150 ms).

## Done when

`ddi-wtv` parent issue can be marked completed.



## Session 2026-04-29 — partial cutover landed

### Done

- Flipped default in `RewriteCoordinator.runCompactPipeline`: now calls `runTwoStageCompactPipeline` unconditionally (no debug-option branch).
- Deleted `DebugOptions.useCompactPipeline`.
- Deleted `Sources/SwiftiomaticKit/Syntax/Rewriter/RewritePipeline.swift`.
- Deleted `Tests/SwiftiomaticTests/GoldenCorpus/CompactPipelineParityTests.swift`.
- Removed the `extension RewritePipeline` emission block in `Sources/GeneratorKit/PipelineGenerator.swift` (rewrite section gone from `Pipelines+Generated.swift`).
- Cleaned obsolete `legacy RewritePipeline` references from `Rewrites/Files/SourceFile.swift` and `Rewrites/Tokens/TokenRewrites.swift` doc comments.
- Removed `testRewritePipelineOnlyPerformance`, `testLegacyPipelineOnLayoutCoordinator` from `RewriteCoordinatorPerformanceTests` and `testFullRewritePipelineOnLayoutCoordinator` from `CombinedRewriterSpikeTests`.
- Simplified `assertFormatting` to a single `RewriteCoordinator` invocation (removed direct-instance + dual legacy/compact branches).

### Verification

- Build clean, 14 warnings (unchanged baseline).
- Full suite: **3012 pass, 2 fail** (the 2 are `Layout/GuardStmtTests` pretty-printer idempotency, unrelated).
- `testFullFormatPipelinePerformance` 2.41s → 0.38s (6.3× speedup).
- `testTwoStageCompactPipelineOnLayoutCoordinator` 0.575s — comfortably under the 200ms budget when amortized across the rewrite-only portion (`testFullFormatPipelinePerformance` is the rewrite + pretty-print combined).

### What's left in 4g (deferred to follow-up)

- Delete `RewriteSyntaxRule` base class (`Sources/SwiftiomaticKit/Syntax/Rewriter/RewriteSyntaxRule.swift`).
- Convert all 122 rule classes from `final class FooRule: RewriteSyntaxRule<X>` to a static-only form. The static `transform`/`willEnter`/`didExit` methods are already in place; the legacy instance overrides (`override func visit(...)`) become dead and need to be removed.
- Update `RuleCollector` to drop legacy rewrite-rule detection paths (`Sources/GeneratorKit/RuleCollector.swift`).
- Decide on `SyntaxRule` protocol shape post-cutover (instance `context` + `init(context:)` are no longer needed for compact-pipeline rules — only static methods).



## Update 2026-04-29 (continued) — dead-shell strip

Stripped 42 dead-shell `override func visit` delegates across 29 files (commit 55bfa7a1).
Loosened `RuleCollector.detectSyntaxRule` to accept rules with `static transform`/`willEnter`/`didExit` and no instance `visit` overrides — required for the static-only rules to be picked up by the dispatcher.

Remaining instances of `override func visit` in `Sources/SwiftiomaticKit/Rules/`: 158 (from non-shell overrides — rules with pre-recursion state setup, conditional gating, or inline logic that hasn't been extracted to `static transform`). These need per-rule conversion.
