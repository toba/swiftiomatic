---
# 0w5-3pm
title: Unify version number across CLI, app, and extension
status: completed
type: task
priority: normal
created_at: 2026-04-11T16:51:40Z
updated_at: 2026-04-11T16:53:50Z
sync:
    github:
        issue_number: "176"
        synced_at: "2026-04-11T17:10:01Z"
---

Version is scattered across 4 places with 3 different values:
- `SwiftiomaticVersion.swift`: `1.0.0`
- `SwiftiomaticCLI.swift`: `0.2.0`  
- Info.plists: hardcoded `1.0`
- pbxproj: `MARKETING_VERSION = 1.0`

Following the SwiftFormat pattern: Swift source constant for CLI, `$(MARKETING_VERSION)` build setting placeholder for app/extension Info.plists.

## Tasks
- [x] Update `SwiftiomaticVersion.current` to `0.18.3` (matches latest git tag)
- [x] CLI reads version from `SwiftiomaticVersion.current` instead of hardcoded string
- [x] Info.plists use `$(MARKETING_VERSION)` placeholder instead of hardcoded `1.0`
- [x] Set `MARKETING_VERSION = 0.18.3` in pbxproj
- [x] Build and verify


## Summary of Changes

Unified version `0.18.3` across all targets:
- `SwiftiomaticVersion.current` (made public) is the single source of truth for Swift code
- CLI `--version` reads from `SwiftiomaticVersion.current.value` instead of a hardcoded string
- Both Info.plists now use `$(MARKETING_VERSION)` / `$(CURRENT_PROJECT_VERSION)` placeholders
- `MARKETING_VERSION` set to `0.18.3` in pbxproj for both app and extension targets

To bump the version in future: update `SwiftiomaticVersion.swift` and `MARKETING_VERSION` in the Xcode project.
