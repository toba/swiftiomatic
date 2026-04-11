---
# 345-ocg
title: Config file selected via file importer not loaded into app
status: completed
type: bug
priority: normal
created_at: 2026-04-11T17:41:06Z
updated_at: 2026-04-11T17:54:52Z
sync:
    github:
        issue_number: "184"
        synced_at: "2026-04-11T18:44:01Z"
---

## Description

The file importer dialog opens and allows selecting a .swiftiomatic.yaml config file, but after selection the app still shows "No configuration file selected" — the chosen file is not actually loaded/applied.

## Steps to Reproduce

1. Open the Swiftiomatic app
2. Go to Configuration File section
3. Click "Choose..."
4. Select a .swiftiomatic.yaml file
5. Observe: Path still shows "No configuration file selected"

## TODO

- [x] Trace the file importer flow in the SwiftUI app
- [x] Identify where the selected URL is (or isn't) being stored/applied
- [x] Create a failing test if possible — not practical (sandboxed app entitlement + file importer UI)
- [x] Fix the issue
- [x] Verify the fix

## Summary of Changes

Removed security-scoped bookmark approach entirely. Config is now read once from the selected file, then persisted as a YAML string in App Group UserDefaults (matching SwiftFormat's pattern). Added `toYAMLString()` and `fromYAMLString()` to `Configuration` for serialization. Removed `com.apple.security.files.bookmarks.app-scope` entitlement.
