---
# xu9-6xv
title: Evaluate swift-syntax 604 prerelease / Swift 6.3.1 alignment
status: completed
type: task
priority: low
created_at: 2026-05-03T16:43:53Z
updated_at: 2026-05-03T16:43:53Z
sync:
    github:
        issue_number: "642"
        synced_at: "2026-05-07T16:13:57Z"
---

## Context

Citation review surfaced two SwiftLint commits (2026-05-03):
- realm/SwiftLint#6627 — Add support for Swift 6.3.1
- realm/SwiftLint#6628 — Use SwiftSyntax 6.4 pre-release 2026-04-21

Investigated whether either is worth mirroring in Swiftiomatic.

## Findings

### Swift 6.3.1 support (SwiftLint #6627)
- 5-line patch: adds `SwiftVersion.sixDotThreeDotOne` and a `#if compiler(>=6.3.1)` branch.
- SwiftLint maintains an enum of Swift versions consumers may *target* — lint metadata, not a toolchain bump.
- **Not applicable to us.** Swiftiomatic doesn't enumerate Swift versions; we already build with `swift-tools-version: 6.3` and `.swiftLanguageMode(.v6)`. No analogous constant exists.

### swift-syntax 604 prerelease (SwiftLint #6628)
- SwiftLint pins `604.0.0-prerelease-2026-04-21`. We pin `603.0.1` (stable, released the same day, 2026-04-21).
- 604 is prerelease-only; no stable 604 exists. SwiftLint tracks prereleases by policy — we don't.
- No known 604-only API we currently need (LintPipeline, CompactSyntaxRewriter, all rules build cleanly on 603.0.1).

### Build time impact
- swift-syntax compile is the dominant build cost in this repo. Bumping to a moving prerelease pin means more frequent full rebuilds of swift-syntax with no perf or feature win.
- 603.0.1 is the stable line — best for build cache stability and CI determinism.

## Decision

**Skip both.** No upgrade. Revisit when:
- a stable 604.0.0 ships, or
- a specific 604 API is needed by a new rule.

## Summary of Changes

No code changes. Documenting the evaluation so future citation reviews can skip these two commits.
