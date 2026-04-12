---
# due-6sw
title: 'Correctable lint rule: @_specialize → @specialize (Swift 6.3)'
status: completed
type: task
priority: normal
created_at: 2026-04-12T02:23:19Z
updated_at: 2026-04-12T02:23:19Z
parent: ogh-b3l
sync:
    github:
        issue_number: "210"
        synced_at: "2026-04-12T03:13:34Z"
---

Simple attribute rename rule. Detects `@_specialize` and auto-corrects to `@specialize`.

File: `Sources/SwiftiomaticKit/Rules/Modernization/Legacy/PreferSpecializeAttributeRule.swift`

## Summary of Changes
- Created `PreferSpecializeAttributeRule` — correctable lint rule with Visitor + Rewriter
- Detects `@_specialize(...)` attribute, replaces with `@specialize(...)`
- All example tests pass
