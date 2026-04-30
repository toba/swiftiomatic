---
# wpg-h5c
title: 'Speed up swift package test wall-time: prebuild lint plugin dominates'
status: review
type: task
priority: high
created_at: 2026-04-30T03:54:34Z
updated_at: 2026-04-30T04:02:27Z
sync:
    github:
        issue_number: "528"
        synced_at: "2026-04-30T04:23:37Z"
---

## Problem

Filtered runs (e.g. `swift package test --filter TernaryExprTests`, 9 cases, 0.035s actual exec) take many seconds of wall time. Three contributors:

1. **Lint SwiftiomaticKit prebuild plugin** runs `sm lint --parallel --recursive` over all of `Sources/SwiftiomaticKit/` on every invocation. If any unrelated file in the tree has a lint error (e.g. an in-flight edit by another agent), the prebuild fails and surfaces as an error even when the cases themselves pass.
2. **GenerateCode plugin** regenerates `*+Generated.swift` each invocation.
3. **Link step** for SwiftiomaticKit + cases + swift-syntax is large.

## Goals

- Filtered runs should not pay for the lint prebuild plugin.
- Generated-code regeneration should be a no-op when nothing changed.
- Lint errors in files outside the change scope should not block runs.

## Possible approaches

- Move the lint prebuild from the SwiftiomaticKit target to a dedicated lint-only target/scheme that is not a test dependency.
- Gate the lint plugin on an env var (e.g. `SM_SKIP_LINT=1`) and document it for fast iteration / agent runs.
- Split SwiftiomaticKit so the slim subset needed by cases does not pull the lint plugin.
- Cache lint results (per-file hash) so reruns when nothing changed are near-instant.

Pick one after measuring the dominant cost (lint vs link vs codegen).

## References

- `Package.swift` — build-tool plugin wiring
- `Plugins/SwiftiomaticBuildToolPlugin/` — the prebuild plugin source



## Summary of Changes

Per-build wall-time cost on filtered tests was dominated by the `SwiftiomaticBuildToolPlugin` prebuild attached to `SwiftiomaticKit`. Prebuild commands are unconditional — SwiftPM re-runs `sm lint --parallel --recursive` over all of `Sources/SwiftiomaticKit/` on every build, regardless of which files changed.

**Change:** Dropped `SwiftiomaticBuildToolPlugin` from `SwiftiomaticKit.plugins` in `Package.swift`. Lint remains available on demand via the `Lint Source Code` command plugin and via CI.

**Codegen was already cached, no change needed:**
- `GenerateCode` plugin uses `buildCommand` with declared `inputFiles`/`outputFiles`, so SwiftPM only invokes `Generator` when an input changed.
- `Sources/Generator/main.swift` writes a SHA-256 fingerprint stamp; if inputs are unchanged it early-exits before any swift-syntax parse.
- `FileGenerator.generateFile(at:)` skips the write when output content is byte-identical, so output mtimes don't bump and downstream targets don't relink.

**Not changed:** the `Swiftiomatic` exec target still attaches the lint prebuild — that affects `sm` builds but not test wall-time. Left in scope for a follow-up if desired.

**Dependency:** `swiftiomatic-plugins` still referenced by the `Swiftiomatic` exec target, so kept in `dependencies:`.

Status set to `review` because the user should verify the wall-time win on their machine (`swift package test --filter TernaryExprTests`).
