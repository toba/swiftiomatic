---
# j7y-saz
title: Move scope filter from toolbar to picker above rule list in nav sidebar
status: ready
type: feature
priority: normal
created_at: 2026-04-12T15:48:20Z
updated_at: 2026-04-12T15:48:20Z
sync:
    github:
        issue_number: "219"
        synced_at: "2026-04-12T16:02:57Z"
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

- [ ] Remove the scope `Picker` from the `.toolbar` block
- [ ] Add a scope `Picker` (segmented or menu style) above the `List` inside the sidebar column of the `NavigationSplitView`
- [ ] Ensure the picker sits between the top of the sidebar and the rule list (and below the search bar if present)
- [ ] Preserve the existing filter behavior (`filteredRules` computed property)
- [ ] Match macOS styling conventions — keep it compact and unobtrusive

## Notes

- Related to #3wr-g9b (search bar placement) — both changes improve the sidebar layout
- The toolbar area should remain clean after this change since the scope filter was the main toolbar item on the Rules tab
