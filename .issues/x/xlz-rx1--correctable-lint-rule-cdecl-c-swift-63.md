---
# xlz-rx1
title: 'Correctable lint rule: @_cdecl → @c (Swift 6.3)'
status: completed
type: task
priority: normal
created_at: 2026-04-12T02:23:18Z
updated_at: 2026-04-12T02:23:18Z
parent: ogh-b3l
sync:
    github:
        issue_number: "214"
        synced_at: "2026-04-12T03:13:35Z"
---

Simple attribute rename rule. Detects `@_cdecl` and auto-corrects to `@c`.

File: `Sources/SwiftiomaticKit/Rules/Modernization/Legacy/PreferCAttributeRule.swift`

## Summary of Changes
- Created `PreferCAttributeRule` — correctable lint rule with Visitor + Rewriter
- Detects `@_cdecl("name")` attribute, replaces with `@c("name")`
- All example tests pass
