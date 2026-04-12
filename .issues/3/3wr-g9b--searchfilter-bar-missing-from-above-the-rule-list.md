---
# 3wr-g9b
title: Search/filter bar missing from above the rule list in nav
status: completed
type: bug
priority: normal
created_at: 2026-04-12T15:43:55Z
updated_at: 2026-04-12T16:52:05Z
sync:
    github:
        issue_number: "217"
        synced_at: "2026-04-12T18:23:35Z"
---

The search bar exists in `RulesTab.swift` using `.searchable(placement: .sidebar)`, but it may not be rendering directly above the rule list as expected. On macOS, `.searchable` with sidebar placement can appear in the toolbar area rather than inline above the list content. The intent is for it to appear visually above the rule list within the sidebar.

## Requirements

- [x] Place the search/filter bar above the rule list in the left nav sidebar
- [x] Filter rules in real time as the user types

## Notes

- This was previously requested but not completed

## Summary of Changes

Fixed by the TabView → NavigationSplitView refactoring in commit 1da1aec. The old structure nested NavigationSplitView inside a TabView, and .searchable without explicit .sidebar placement caused macOS to hoist the search field into the toolbar. The new flat NavigationSplitView with .searchable(placement: .sidebar) renders the search bar inline above the rule list as intended.
