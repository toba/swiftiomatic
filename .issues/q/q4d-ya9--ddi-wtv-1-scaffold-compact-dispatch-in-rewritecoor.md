---
# q4d-ya9
title: 'ddi-wtv-1: scaffold compact dispatch in RewriteCoordinator'
status: completed
type: task
priority: high
created_at: 2026-04-28T02:42:08Z
updated_at: 2026-04-28T02:48:57Z
parent: ddi-wtv
sync:
    github:
        issue_number: "491"
        synced_at: "2026-04-28T02:56:06Z"
---

Wire `RewriteCoordinator` to branch on the configured style.

## Goal

When `config[StyleSetting.self] == .compact`, take the new code path; otherwise fall back to the existing `RewritePipeline`. The new path is *empty for now* — it still produces correct output by delegating to the legacy pipeline as a temporary inner stub. This lets every later sub-issue land additively without breaking the build.

## Tasks

- [x] Read current `RewriteCoordinator.format(...)` to find the rewrite invocation site
- [x] Add a private `runCompactPipeline(_:)` helper; for now it just calls the legacy `RewritePipeline.rewrite`
- [x] Branch on `configuration[StyleSetting.self]`; `.roomy` throws `styleNotImplemented`
- [x] Add a smoke test (`compactPipelineDispatchProducesOutput` in `StyleTests`)

## Summary of Changes

- `Sources/SwiftiomaticKit/Syntax/Rewriter/RewriteCoordinator.swift`: extract the rewrite invocation into `runCompactPipeline(_:context:)`; route `format(syntax:...)` through a switch on `configuration[StyleSetting.self]`.
- `Tests/SwiftiomaticTests/API/StyleTests.swift`: add `compactPipelineDispatchProducesOutput` smoke test.

The body of `runCompactPipeline` still delegates to the legacy `RewritePipeline`. Sub-issues `ogx-lb7` (combined rewriter codegen) and `g6t-gcm` (structural pass ordering) replace it incrementally.

## Done when

Build green, all existing tests pass, the new branch is exercised by at least one test.
