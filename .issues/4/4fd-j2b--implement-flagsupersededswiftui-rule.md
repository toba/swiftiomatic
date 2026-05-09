---
# 4fd-j2b
title: Implement FlagSupersededSwiftUI rule
status: completed
type: feature
priority: normal
created_at: 2026-05-09T16:16:21Z
updated_at: 2026-05-09T16:22:31Z
parent: z75-gax
sync:
    github:
        issue_number: "679"
        synced_at: "2026-05-09T17:07:18Z"
---

Item 2 from z75-gax. Flag-only diagnostics for superseded SwiftUI APIs:
- @StateObject, @ObservedObject, @EnvironmentObject, @Published attributes
- ObservableObject protocol conformance
- NavigationView usage

Table-driven, type/attribute name match.

- [x] Write tests
- [x] Implement rule
- [x] Verify build/test passes



## Summary of Changes

- Added `Sources/SwiftiomaticKit/Rules/Swiftui/FlagSupersededSwiftUI.swift` — flag-only lint rule covering `@StateObject`, `@ObservedObject`, `@EnvironmentObject`, `@Published`, `ObservableObject` conformance (class/struct/extension/protocol), and `NavigationView` usage.
- Added `Tests/SwiftiomaticTests/Rules/FlagSupersededSwiftUITests.swift` — 12 tests covering positive cases, mixed inheritance, extension conformance, and modern-pattern non-flagging (`@Observable`, `@State`, `NavigationStack`, `NavigationSplitView`).
- Full test suite: 3310 passed, 0 failed.
