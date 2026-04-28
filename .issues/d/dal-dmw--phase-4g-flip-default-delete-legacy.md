---
# dal-dmw
title: 'Phase 4g: flip default + delete legacy'
status: ready
type: task
priority: high
created_at: 2026-04-28T15:50:43Z
updated_at: 2026-04-28T15:50:43Z
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
