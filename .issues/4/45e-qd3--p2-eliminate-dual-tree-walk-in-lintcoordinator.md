---
# 45e-qd3
title: 'P2: Eliminate dual tree walk in LintCoordinator'
status: ready
type: task
priority: high
created_at: 2026-04-30T15:57:19Z
updated_at: 2026-04-30T15:57:19Z
parent: 6xi-be2
sync:
    github:
        issue_number: "546"
        synced_at: "2026-04-30T16:27:54Z"
---

**Location:** `Sources/SwiftiomaticKit/Syntax/Linter/LintCoordinator.swift:170-173`

`LintCoordinator.lint` runs `RewritePipeline(context:).rewrite(...)` and discards the result, then runs `LintPipeline.walk(...)`. The rewriter is invoked solely so static `willEnter`/`transform` hooks of compact-pipeline rules fire in lint mode. We pay full rewrite cost (node copy/edit machinery) just to drive findings.

## Potential performance benefit

Roughly halves per-file lint cost for compact-pipeline-heavy files: the rewriter walk allocates new node copies for every transform, even when the result is discarded. On a large file with many compact rules active that's a substantial allocation + ARC cost on top of the lint walk that immediately follows.

## Reason deferred

Architectural: requires either (a) a lint-only mode for `CompactSyntaxRewriter` that skips actual mutation, (b) moving compact-pipeline finding emission into `LintPipeline` via a generated parallel dispatch, or (c) a `SyntaxVisitor` (no `SyntaxRewriter`) variant to drive the static hooks. All three options touch generated code and need careful equivalence testing against the current finding output. Pairs naturally with P3.
