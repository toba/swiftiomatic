---
# i47-g2p
title: 'PreferOfficialSpecialize: @_specialize → @specialize'
status: completed
type: feature
priority: normal
created_at: 2026-04-30T20:22:11Z
updated_at: 2026-04-30T20:27:12Z
parent: 7h4-72k
sync:
    github:
        issue_number: "580"
        synced_at: "2026-04-30T23:13:22Z"
---

Rewrite `@_specialize` to `@specialize` (Swift 6.3 official spelling).

Same shape as `PreferOfficialCDecl`.

## Plan

- [x] Failing test
- [x] Implement `PreferOfficialSpecialize` (StaticFormatRule, group .declarations, default warn)
- [x] Wire into `RewritePipeline.visit(_: AttributeSyntax)`
- [x] Verify test passes; regenerate schema



## Summary of Changes

- Added `PreferOfficialSpecialize.swift` (group `.declarations`, default `.warn`).
- Added `PreferOfficialSpecializeTests.swift` — 4/4 passing.
- Wired into `RewritePipeline.visit(_: AttributeSyntax)`.
- `schema.json` regenerated; `preferOfficialSpecialize` entry present.
