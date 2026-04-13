---
# 7re-wxk
title: Move Format Options button above the rule list
status: completed
type: bug
priority: normal
created_at: 2026-04-13T13:35:44Z
updated_at: 2026-04-13T13:39:31Z
sync:
    github:
        issue_number: "258"
        synced_at: "2026-04-13T13:40:14Z"
---

## Problem

The "Format Options" button currently appears within the rule list. It should be positioned above the rule list instead.

## Tasks

- [x] Locate the Format Options button in the SwiftUI view hierarchy
- [x] Move it above the rule list
- [x] Verify layout with screenshot


## Summary of Changes

Moved the Format Options button out of the `List` and into the `.safeAreaInset(edge: .top)` area in `ContentView.swift`. It now sits between the search/filter bar and the scrollable rule list, pinned in place so it never scrolls out of view. Selection highlighting uses a tinted rounded rectangle background.
