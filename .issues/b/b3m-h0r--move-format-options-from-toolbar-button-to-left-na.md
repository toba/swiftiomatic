---
# b3m-h0r
title: Move Format Options from toolbar button to left nav item
status: ready
type: feature
priority: normal
created_at: 2026-04-12T15:42:59Z
updated_at: 2026-04-12T15:42:59Z
sync:
    github:
        issue_number: "221"
        synced_at: "2026-04-12T16:02:57Z"
---

The "Options" toolbar button should be removed and replaced with a navigation item.

## Requirements

- [ ] Remove the "Options" toolbar button
- [ ] Add a "Format Options" item at the top of the left navigation sidebar
- [ ] When selected, show the existing options view in the detail area (same content, new location)

## Notes

- This aligns with the document-based app direction — configuration lives in the nav hierarchy, not the toolbar
- The existing options view can be reused as-is; only the navigation path to it changes
