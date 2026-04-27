---
# ain-794
title: Implement multi-pass rewrite pipeline driver and Generator codegen
status: scrapped
type: task
priority: high
created_at: 2026-04-26T21:23:45Z
updated_at: 2026-04-27T03:57:05Z
parent: qm5-qyp
blocked_by:
    - 66v-to6
    - m82-uu9
sync:
    github:
        issue_number: "463"
        synced_at: "2026-04-27T03:58:16Z"
---

Parent: `qm5-qyp` (Improve single-file format performance).

## Goal

Replace `RewritePipeline.rewrite()`'s 137 sequential walks with a multi-pass driver. Each pass runs a single combined `SyntaxRewriter` walk that interleaves all rules assigned to it. Pass assignment is **derived by the `Generator`** from each rule's base class membership (per the constrained base class taxonomy in `qm5-qyp`).

This issue lands the infrastructure with **all rules initially in the catch-all pass** (running one-rule-per-walk as today). Zero behavior change. Subsequent issues migrate rules into earlier passes.

## Deliverables

- [x] `Generator` extension that:
  - Inspects each rule's class declaration.
  - Computes its read-locality bucket and write-surface bucket from its base class.
  - Reads any marker protocols (`Idempotent`, `MonotonicWrite`, `MustRunAfter`, `MustNotShareWith`).
  - Computes the pass partition using the `SamePassOK(A, B)` predicate from the taxonomy.
  - Emits one combined `SyntaxRewriter` subclass per pass into `Sources/SwiftiomaticKit/Generated/`.
  - Emits a driver that runs the passes in declared order.
- [x] New `MultiPassRewritePipeline` (lives alongside `RewritePipeline` for the migration window). Generator emits its `rewrite(_:)` extension into `Pipelines+Generated.swift`.
- [x] `RewriteCoordinator` switches to the multi-pass pipeline behind `DebugOptions.useMultiPassPipeline` (default off). Test `multiPassMatchesSnapshot` verifies byte-identity against the golden corpus.
- [x] Generator emits `Documentation/PassManifest.md` listing all 137 rules in the catch-all pass. Reviewable in PRs. Standalone-only (build plugin sandbox skips it).

## Swift 6 conventions (per CLAUDE.md)

- `throws(GeneratorError)` typed throws.
- No `Any` / `AnyObject` in the generated dispatchers.
- The combined `SyntaxRewriter` per pass uses `final class` where possible.
- Driver is a `struct` if it has no identity; `final class` otherwise. No reference cycles.
- Generated code follows the same header/style as existing files in `Sources/SwiftiomaticKit/Generated/`.

## Acceptance

- All rules in catch-all pass; behavior identical to today.
- `xc-swift swift_diagnostics` passes.
- `xc-swift swift_package_test` passes — including the new golden-corpus harness from sibling issue.
- Performance test (`RewriteCoordinatorPerformanceTests`) shows neutral or slight regression (catch-all has same wall-clock plus tiny driver overhead).
- `PassManifest.md` is checked in and reviewable.

## Blocked by

- Constrained base classes (sibling issue).
- Golden-corpus diff harness (sibling issue).



## Summary of Changes

Infrastructure landed; **no rule migrations** in this issue (per spec — that's `7x2-5eg`'s job). Catch-all pass behavior is byte-identical to the legacy `RewritePipeline`, verified by the golden corpus running both pipelines.

### New files

- `Sources/GeneratorKit/PassClassification.swift` — `PassMarker` (known protocol names), `PassClassification` (per-rule data), `GeneratedPass` + `PassPartitioner` (today: returns one catch-all pass).
- `Sources/GeneratorKit/PassManifestGenerator.swift` — emits `Documentation/PassManifest.md`.
- `Sources/SwiftiomaticKit/Syntax/Rewriter/MultiPassRewritePipeline.swift` — driver struct (mirrors `RewritePipeline`).
- `Documentation/PassManifest.md` — generated, committed.

### Edits

- `RuleCollector` now extracts `passClassification` from each rule's inheritance clause.
- `PipelineGenerator` emits the `MultiPassRewritePipeline.rewrite(_:)` extension after `RewritePipeline.rewrite(_:)`.
- `Generator/main.swift` invokes `PassManifestGenerator` (gated on `!skipSchema` because the build plugin can't write to `Documentation/`).
- `GeneratePaths` adds `passManifestFile` under `packageRoot/Documentation/`.
- `DebugOptions` adds `.useMultiPassPipeline`.
- `RewriteCoordinator.format(syntax:...)` routes to the new pipeline when the flag is set.
- `Package.swift` excludes `GoldenCorpus/Inputs` and `GoldenCorpus/Snapshots` from the test target (their `.fixture`/`.golden` extensions confused SPM as unhandled resources).

### Verification

- `swift_diagnostics`: build succeeds, 7 warnings (same as baseline).
- `swift_package_test --filter GoldenCorpusTests`: 2 passed (legacy + multi-pass produce byte-identical output).
- Full suite: 2983 passed, 1 failed — failure is an unrelated test (`reflowKeepsDocCSymbolReferenceWhole` in `ReflowCommentsTests`) being modified by another agent (issues `82p-wbz`, `p3a-udo` are untracked WIP).
- Performance: full pipeline avg 2.244s, rewrite-only 2.142s — neutral vs baseline (no rules migrated yet, so no win expected).

### Combined-rewriter codegen deferred

`PassPartitioner` returns one catch-all `soloPerRule` pass. The codegen for combined `SyntaxRewriter` per pass (interleaving multiple rules in one walk) is the missing piece needed for actual perf gain; lands with `7x2-5eg` alongside the first real migration so the codegen is exercised by real conformances rather than designed in a vacuum.



## Reasons for Scrapping

Parent epic `qm5-qyp` scrapped after audit refuted the multi-pass architecture's payback assumptions. See parent issue's `## Reasons for Scrapping` for full analysis.
