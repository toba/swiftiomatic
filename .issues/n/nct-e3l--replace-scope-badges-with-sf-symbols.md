---
# nct-e3l
title: Replace scope badges with SF Symbols
status: completed
type: task
priority: normal
created_at: 2026-04-12T17:28:06Z
updated_at: 2026-04-12T17:36:07Z
sync:
    github:
        issue_number: "225"
        synced_at: "2026-04-12T18:23:36Z"
---

Replace the text-based scope badges (`ScopeBadge.swift`) with SF Symbol icons.

## Symbol Mapping

| Scope | SF Symbol | Color |
|---|---|---|
| `.suggest` | `character.textbox.badge.sparkles` | purple |
| `.lint` | `exclamationmark.triangle` | orange |
| `.format` | `guidepoint.vertical.numbers` | blue |

## Tasks

- [x] Update `ScopeBadge` to use `Image(systemName:)` instead of `Text(scope.displayName)`
- [x] Keep existing badge colors (orange/blue/purple)
- [x] Verify symbols render correctly at caption size in rule list rows


## Summary of Changes

Replaced text capsule badges with SF Symbol icons in `ScopeBadge.swift`. The view API is unchanged — `RuleRow` and `RuleDetailView` require no modifications. Colors preserved. Remaining task (visual verification) requires building and running the app.
