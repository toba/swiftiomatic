---
# ar4-yf4
title: Remove support for Swift < 6 and Swift 5 language mode
status: completed
type: task
priority: normal
created_at: 2026-02-27T23:33:59Z
updated_at: 2026-02-28T01:27:53Z
sync:
    github:
        issue_number: "6"
        synced_at: "2026-03-01T01:01:29Z"
---

Match Thesis/Core target Swift settings across all Swiftiomatic targets.

## Reference: Thesis Core Settings (Xcode)

- Swift 6.0, macOS 15.5, `SWIFT_STRICT_CONCURRENCY = complete`
- `SWIFT_APPROACHABLE_CONCURRENCY = YES`
- `-enable-actor-data-race-checks` in OTHER_SWIFT_FLAGS
- `SWIFT_ENABLE_EXPLICIT_MODULES = YES`
- 9 upcoming features enabled: `DisableOutwardActorIsolation`, `ExistentialAny`, `GlobalConcurrency`, `InferSendableFromCaptures`, `InternalImportsByDefault`, `IsolatedDefaultValues`, `MemberImportVisibility`, `NonisolatedNonsendingByDefault`, `RegionBasedIsolation`

## SPM Equivalents to Apply

```swift
swiftSettings: [
    .swiftLanguageMode(.v6),
    .enableExperimentalFeature("StrictConcurrency"),
    .enableExperimentalFeature("ApproachableConcurrency"),
    .enableExperimentalFeature("RegionBasedIsolation"),
    .enableUpcomingFeature("ExistentialAny"),
    .enableUpcomingFeature("InternalImportsByDefault"),
    .enableUpcomingFeature("MemberImportVisibility"),
    .enableUpcomingFeature("GlobalConcurrency"),
    .enableUpcomingFeature("DisableOutwardActorIsolation"),
    .enableUpcomingFeature("InferSendableFromCaptures"),
    .enableUpcomingFeature("IsolatedDefaultValues"),
    .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
    .unsafeFlags(["-enable-actor-data-race-checks"]),
]
```

Note: In swift-tools-version 6.2, many of these are already defaults in v6 mode. Some (`ExistentialAny`, `RegionBasedIsolation`, `InferSendableFromCaptures`, `GlobalConcurrency`) are already implied. Focus on the ones that add strictness beyond the default.

## Targets to Update

- [x] `Swiftiomatic` (CLI) — changed to v6 + ApproachableConcurrency, InternalImportsByDefault, MemberImportVisibility, DisableOutwardActorIsolation, NonisolatedNonsendingByDefault
- [x] `SwiftLintCoreMacros` (macro) — added v6 language mode
- [x] `SwiftiomaticTests` (tests) — added v6 language mode
- [x] `DyldWarningWorkaround` — C target, no Swift settings needed

## Notes

- Swiftiomatic is swift-tools-version 6.2; Thesis is Xcode-native Swift 6.0
- Some features may already be on by default in 6.2 v6 mode — verify and only add what is additive
- The Swiftiomatic CLI target is currently v5 mode; expect concurrency errors when switching to v6
- SwiftLintCoreMacros should compile cleanly under v6 (already confirmed in memory)


## Summary of Changes

- Switched all Swift targets from v5 to v6 language mode
- Enabled strict concurrency features: ApproachableConcurrency, InternalImportsByDefault, MemberImportVisibility, DisableOutwardActorIsolation, NonisolatedNonsendingByDefault
- Stripped all unnecessary `public`/`open` access modifiers across 257 files (executable target has no public API)
- Added `@unchecked Sendable` to types used across concurrency boundaries: Configuration, RuleStorage, Linter, CollectedLinter, LintableFilesVisitor, Excluder, CompilerInvocations
- Added `nonisolated(unsafe)` to lock-protected global mutable state caches
- Made LintableFileManager protocol require Sendable
- Added confidence/suggestion fields to ReasonedRuleViolation and StyleViolation
- Added RuleKind cases: .suggest, .concurrency, .observation
- Added Foundation import to files using .capitalized (MemberImportVisibility)
- Build: 0 errors, 0 warnings. All 12 tests pass.
