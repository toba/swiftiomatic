---
# 39g-fzl
title: Bump swift-syntax to 605.x for Swift 6.4 support
status: deferred
type: task
priority: normal
tags:
    - Swift 6.4
created_at: 2026-06-09T15:42:43Z
updated_at: 2026-06-09T15:42:43Z
sync:
    github:
        issue_number: "730"
        synced_at: "2026-06-12T15:17:17Z"
---

SwiftLint moved to swift-syntax `605.0.0-prerelease-2026-06-08` (realm/SwiftLint commit `2b8db54e`, PR #6766). Swiftiomatic stays pinned at **603.0.1**. When Swift 6.4 / swift-syntax 605 ships stable, evaluate bumping.

## What's in 605 (vs 604.0.0-prerelease-2026-06-05, 44 commits)

### Language / parser
- `@warn` renamed to `@diagnose` (swiftlang/swift-syntax#3305) — SourceWarningControl
- `@diagnose` honors `#if` directives; promoted from `@_spi(ExperimentalLanguageFeatures)` to public API
- `#if compiler()` / `#if canImport()` now accept up to five version components (#3350)
- Better missing-node diagnostics: prefer child name over type name (#3328); return `MissingPatternSyntax` for empty pattern positions (#3329)

### Plugin / macros
- Plugin message protocol bumped to v8 for `Syntax.Kind.accessor` (#3339)
- `SwiftSyntaxMacrosTestSupport` records issues via Swift Testing `Issue.record()` under ST-0021, falls back to `XCTFail()` on older toolchains (#3192)

### Build / packaging
- Default release version bumped to 605.0.0; version marker module added (#3325)

### Refactorings
- "Convert stored property to computed" refactoring added (#3326)

## Deferral Notes

- swift-syntax 605 is still pre-release; wait for stable tag.
- Need to audit rules that touch attributes (e.g., `SortModifiers`) for the `@warn` → `@diagnose` rename — if any user code uses `@warn`, our handling must accept both during transition, or we emit on the new name only post-bump.
- Plugin protocol v8 bump shouldn't affect us directly (we don't ship as a SwiftSyntax macro plugin), but verify before bumping.
- Confirm all current rules still parse/round-trip against 605 syntax tree shape — esp. anything depending on `MissingPatternSyntax` placement.

## Follow-ups (to file when work begins)

- [ ] Audit `SortModifiers` and attribute-related rules for `@warn` / `@diagnose`
- [ ] Run full test suite against 605 to surface AST shape diffs
- [ ] Re-pin Package.swift and update cited swift-syntax `last_checked_sha`
