---
# j7y-saz
title: Move scope filter from toolbar to picker above rule list in nav sidebar
status: completed
type: feature
priority: normal
created_at: 2026-04-12T15:48:20Z
updated_at: 2026-04-12T17:12:53Z
sync:
    github:
        issue_number: "219"
        synced_at: "2026-04-12T18:23:35Z"
---

The scope filter (All / Lint / Format / Suggest) is currently a segmented `Picker` in the toolbar of the Rules tab (`RulesTab.swift:42-47`). It should be moved out of the toolbar and placed directly above the rule list inside the sidebar, so the filter is visually co-located with the content it controls.

## Current Implementation

In `Xcode/SwiftiomaticApp/Views/RulesTab.swift`:

- `@State private var scopeFilter: ScopeFilter = .all` (line 7)
- `ScopeFilter` enum with cases: `all`, `lint`, `format`, `suggest` (lines 9-14)
- Toolbar segmented picker (lines 40-48):
  ```swift
  .toolbar {
    ToolbarItem {
      Picker("Scope", selection: $scopeFilter) {
        ForEach(ScopeFilter.allCases, id: \.self) { filter in
          Text(filter.rawValue).tag(filter)
        }
      }
      .pickerStyle(.segmented)
    }
  }
  ```

## Requirements

- [x] Remove the scope `Picker` from the `.toolbar` block
- [x] Add a scope `Picker` (menu style) inline with the search field at the top of the sidebar
- [x] Picker sits inline with the search bar at its trailing end
- [x] Preserve the existing filter behavior (`filteredRules` computed property)
- [x] Match macOS styling conventions — compact menu picker

## Notes

- Related to #3wr-g9b (search bar placement) — both changes improve the sidebar layout
- The toolbar area should remain clean after this change since the scope filter was the main toolbar item on the Rules tab


## Summary of Changes

Replaced `.searchable` + toolbar segmented picker with a custom `safeAreaInset(edge: .top)` bar containing a plain search `TextField` and a `.menu`-style scope `Picker` inline on the same row. The scope filter now sits at the trailing end of the search input in the sidebar. All filtering logic unchanged.
