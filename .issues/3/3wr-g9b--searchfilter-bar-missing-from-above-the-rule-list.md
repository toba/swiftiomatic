---
# 3wr-g9b
title: Search/filter bar missing from above the rule list in nav
status: ready
type: bug
priority: normal
created_at: 2026-04-12T15:43:55Z
updated_at: 2026-04-12T15:45:01Z
sync:
    github:
        issue_number: "217"
        synced_at: "2026-04-12T16:02:57Z"
---

The search bar exists in `RulesTab.swift` using `.searchable(placement: .sidebar)`, but it may not be rendering directly above the rule list as expected. On macOS, `.searchable` with sidebar placement can appear in the toolbar area rather than inline above the list content. The intent is for it to appear visually above the rule list within the sidebar.

## Requirements

- [ ] Place the search/filter bar above the rule list in the left nav sidebar
- [ ] Filter rules in real time as the user types

## Notes

- This was previously requested but not completed
