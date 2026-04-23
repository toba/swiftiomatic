---
# l5w-ti1
title: Remove unsafe Swift patterns
status: completed
type: task
priority: normal
created_at: 2026-04-18T18:05:18Z
updated_at: 2026-04-18T18:08:34Z
sync:
    github:
        issue_number: "348"
        synced_at: "2026-04-23T05:30:25Z"
---

Replace `@unchecked Sendable` and `nonisolated(unsafe)` with proper safe alternatives.

- [~] Phase 1a: ~~Remove `nonisolated(unsafe)` from regex statics in RuleMask.swift~~ — `Regex` not Sendable in this toolchain
- [~] Phase 1b: ~~Remove `nonisolated(unsafe)` from metatype in RuleBasedFindingCategory.swift~~ — `Rule.Type` not Sendable (Rule doesn't inherit Sendable)
- [x] Phase 2: Make DiagnosticsEngine Sendable with Mutex
- [x] Phase 3: Make FileToProcess Sendable (eager sourceText)
- [~] Phase 4: ~~Remove @unchecked Sendable from Frontend hierarchy~~ — non-final classes can't conform to Sendable; kept @unchecked but internals now properly protected by Mutex
- [x] Phase 5: Protect DocCommentSummary testing flag with Mutex


## Summary of Changes

- `DiagnosticsEngine`: now `Sendable` with `Mutex<State>` protecting `hasErrors`/`hasWarnings`; handlers typed `@Sendable`
- `FileToProcess`: now `Sendable` with eager `let sourceText` replacing `lazy var`
- `Frontend` hierarchy: still `@unchecked Sendable` (non-final class limitation) but `configurationProvider` now wrapped in `Mutex`
- `DocCommentSummary._forcesFallbackModeForTesting`: now `Mutex`-backed computed property
- Phase 1 reverted: `Regex` and `Rule.Type` aren't Sendable in this toolchain
