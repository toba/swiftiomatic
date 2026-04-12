---
# 7u7-t0o
title: 'Xcode app build fails: SwiftiomaticKit types not visible to SwiftiomaticApp'
status: completed
type: bug
priority: high
created_at: 2026-04-12T15:45:56Z
updated_at: 2026-04-12T16:01:09Z
sync:
    github:
        issue_number: "220"
        synced_at: "2026-04-12T16:02:57Z"
---

The install script fails (exit 65) because the Xcode app target (`SwiftiomaticApp`) cannot resolve types from `SwiftiomaticKit`.

## Errors

- `cannot find type 'RuleConfigurationEntry' in scope` — AppModel.swift, RulesTab.swift, RuleRow.swift, RuleDetailView.swift
- `cannot find type 'Scope' in scope` — ScopeBadge.swift

## Investigation

- [ ] Check if `RuleConfigurationEntry` and `Scope` are marked `public` in SwiftiomaticKit
- [ ] Check how the Xcode project links SwiftiomaticKit to SwiftiomaticApp
- [ ] Fix access control or project linkage
- [ ] Verify build succeeds


## Summary of Changes

- Exposed `SwiftiomaticSyntax` as a library product in `Package.swift`
- Added `SwiftiomaticSyntax` as a package product dependency on `SwiftiomaticApp` and `SwiftiomaticExtension` targets in the Xcode project
- Added `import SwiftiomaticSyntax` to all app view/model files that reference types from that module (AppModel, RulesTab, RuleRow, RuleDetailView, ScopeBadge, OptionsTab)
- Fixed `AboutView.swift` missing `lastKnownFileType` in project by remove/re-add cycle

Root cause: commit 581eadd extracted types into `SwiftiomaticSyntax` but the Xcode project wasn't updated to depend on it. With `InternalImportsByDefault` and `MemberImportVisibility` enabled, `public import SwiftiomaticSyntax` in SwiftiomaticKit wasn't sufficient for the Xcode app target.
