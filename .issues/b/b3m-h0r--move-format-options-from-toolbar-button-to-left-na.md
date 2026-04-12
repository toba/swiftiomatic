---
# b3m-h0r
title: Move Format Options from toolbar button to left nav item
status: completed
type: feature
priority: normal
created_at: 2026-04-12T15:42:59Z
updated_at: 2026-04-12T16:27:49Z
sync:
    github:
        issue_number: "221"
        synced_at: "2026-04-12T16:28:29Z"
---

The "Options" toolbar button should be removed and replaced with a navigation item.

## Requirements

- [x] Remove the "Options" toolbar button
- [x] Add a "Format Options" item at the top of the left navigation sidebar
- [x] When selected, show the existing options view in the detail area (same content, new location)

## Notes

- This aligns with the document-based app direction — configuration lives in the nav hierarchy, not the toolbar
- The existing options view can be reused as-is; only the navigation path to it changes


## Summary of Changes

- Replaced `TabView` (Rules/Options tabs) with a single `NavigationSplitView`
- Added "Format Options" as a pinned sidebar item above the rules list
- Introduced `SidebarSelection` enum to drive detail area content
- Renamed `OptionsTab` struct to `OptionsDetailView`
- Deleted `RulesTab.swift` (logic moved into `ContentView`)
- Removed `RulesTab.swift` from Xcode project
