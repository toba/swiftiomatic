---
# uxh-u9g
title: 'Suggest rule: SwiftUI superseded patterns'
status: completed
type: task
priority: normal
created_at: 2026-04-12T02:23:23Z
updated_at: 2026-04-12T02:23:23Z
parent: ogh-b3l
sync:
    github:
        issue_number: "211"
        synced_at: "2026-04-12T03:13:35Z"
---

Detects SwiftUI patterns superseded by modern alternatives.

File: `Sources/SwiftiomaticKit/Rules/Frameworks/SwiftUI/SwiftUISupersededPatternsRule.swift`

Patterns detected:
- `ObservableObject` conformance → `@Observable`
- `@StateObject` → `@State`
- `@ObservedObject` → `@State`/`@Bindable`
- `@EnvironmentObject` → `@Environment`
- `NavigationView` → `NavigationStack`/`NavigationSplitView`

## Summary of Changes
- Created `SwiftUISupersededPatternsRule` — suggest-scope rule with typed violation messages
- Visits ClassDeclSyntax (ObservableObject), AttributeSyntax (wrappers), DeclReferenceExprSyntax (NavigationView)
- All example tests pass
