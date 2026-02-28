---
# ar4-yf4
title: Remove support for Swift < 6 and Swift 5 language mode
status: in-progress
type: task
priority: normal
created_at: 2026-02-27T23:33:59Z
updated_at: 2026-02-28T00:09:46Z
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

- [ ] `Swiftiomatic` (CLI) — currently `.swiftLanguageMode(.v5)`, change to v6 + all settings
- [ ] `SwiftLintCoreMacros` (macro) — no swiftSettings currently, add v6 + settings
- [ ] `SwiftiomaticTests` (tests) — no swiftSettings currently, add v6 + settings
- [ ] `DyldWarningWorkaround` — C target, no Swift settings needed

## Notes

- Swiftiomatic is swift-tools-version 6.2; Thesis is Xcode-native Swift 6.0
- Some features may already be on by default in 6.2 v6 mode — verify and only add what is additive
- The Swiftiomatic CLI target is currently v5 mode; expect concurrency errors when switching to v6
- SwiftLintCoreMacros should compile cleanly under v6 (already confirmed in memory)
