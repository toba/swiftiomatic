---
# qgh-6um
title: 'Correctable lint rule: redundant @MainActor on View'
status: completed
type: task
priority: normal
created_at: 2026-04-12T02:23:20Z
updated_at: 2026-04-12T02:23:20Z
parent: ogh-b3l
sync:
    github:
        issue_number: "213"
        synced_at: "2026-04-12T03:13:35Z"
---

Detects and auto-removes `@MainActor` on types conforming to View, ViewModifier, App, or Scene (implicitly @MainActor).

File: `Sources/SwiftiomaticKit/Rules/Frameworks/SwiftUI/RedundantMainActorViewRule.swift`

## Summary of Changes
- Created `RedundantMainActorViewRule` — correctable lint rule using Visitor-based corrections
- Checks struct/class/enum declarations for SwiftUI protocol conformance + @MainActor attribute
- Removes @MainActor and cleans up trivia
- All example tests pass
