---
# fq2-2k0
title: Fix SF Symbol sizing and placement in rule list
status: completed
type: bug
priority: normal
created_at: 2026-04-12T18:22:29Z
updated_at: 2026-04-12T18:22:29Z
sync:
    github:
        issue_number: "224"
        synced_at: "2026-04-12T18:23:36Z"
---

SF Symbols in the rule list sidebar were too small, appeared after the rule name instead of before, and the scope filter picker lacked symbols.

## Tasks

- [x] Remove `.imageScale(.small)` from `ScopeBadge` so symbols render at natural size
- [x] Move `ScopeBadge` before rule name text in `RuleRow`
- [x] Remove `.font(.caption2)` from wand icon in `RuleRow`
- [x] Add `symbolName` to `ScopeFilter` enum in `ContentView`
- [x] Use `Label` with SF Symbol in scope filter picker (default color)

## Files Changed

- `Xcode/SwiftiomaticApp/Views/ScopeBadge.swift`
- `Xcode/SwiftiomaticApp/Views/RuleRow.swift`
- `Xcode/SwiftiomaticApp/Views/ContentView.swift`

## Summary of Changes

Fixed three UX issues: enlarged SF Symbols by removing size constraints, moved scope icon before rule name in each row, and added scope symbols to the filter picker dropdown.
