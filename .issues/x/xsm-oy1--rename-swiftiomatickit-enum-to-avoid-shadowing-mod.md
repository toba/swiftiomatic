---
# xsm-oy1
title: Rename SwiftiomaticKit enum to avoid shadowing module name
status: completed
type: task
priority: normal
created_at: 2026-04-11T18:16:18Z
updated_at: 2026-04-11T18:25:35Z
sync:
    github:
        issue_number: "187"
        synced_at: "2026-04-11T18:44:02Z"
---

`Sources/SwiftiomaticKit/PublicAPI.swift:3` defines `public enum SwiftiomaticKit` inside the `SwiftiomaticKit` module. This shadows the module name, making `ModuleName.Type` disambiguation impossible (e.g. `SwiftiomaticKit.Configuration` resolves to the enum, not the module).

Rename the enum to `Swiftiomatic` (matches the CLI name) or another non-colliding name. Update all call sites.

- [x] Rename enum in `PublicAPI.swift`
- [x] Update callers (Xcode extension target, any external consumers)
- [x] Verify build


## Summary of Changes

Renamed `public enum SwiftiomaticKit` to `public enum Swiftiomatic` in `PublicAPI.swift` and updated all 6 call sites across the Xcode app and extension targets. No module-level changes needed — `import SwiftiomaticKit` statements remain unchanged. SPM and Xcode builds both pass.
