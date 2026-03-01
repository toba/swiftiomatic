---
# 0fw-bl2
title: Rename +Configuration files and types to +Options
status: in-progress
type: task
priority: normal
created_at: 2026-03-01T22:10:46Z
updated_at: 2026-03-01T22:44:21Z
parent: 55b-kur
sync:
    github:
        issue_number: "130"
        synced_at: "2026-03-01T22:41:02Z"
---

Rename all rule `+Configuration` files to `+Options` and their contained types similarly.

## Changes
- [ ] Rename all `*+Configuration.swift` files to `*+Options.swift`
- [x] Rename all `*Configuration` types within to `*Options`
- [x] Rename `var configuration` properties in rule files to `var options`
- [x] Verify build succeeds
- [x] Verify tests pass

## Examples
- `RedundantVoidReturnRule+Configuration.swift` → `RedundantVoidReturnRule+Options.swift`
- `RedundantVoidReturnConfiguration` → `RedundantVoidReturnOptions`
- `var configuration = RedundantVoidReturnConfiguration()` → `var options = RedundantVoidReturnOptions()`


## Summary of Changes

Renamed all rule `+Configuration` files to `+Options`, renamed types within from `*Configuration` to `*Options`, and renamed the `var configuration` property on the `Rule` protocol (and all conforming types) to `var options`. Also renamed `@ConfigurationElement` → `@OptionElement` and `AcceptableByConfigurationElement` → `AcceptableByOptionElement` in infrastructure files. All 4454 tests pass, both SPM and Xcode builds succeed.
