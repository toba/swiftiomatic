---
# f1f-eco
title: Add 9 new configuration groups for ungrouped rules
status: completed
type: task
priority: normal
created_at: 2026-04-23T16:29:28Z
updated_at: 2026-04-23T16:32:54Z
sync:
    github:
        issue_number: "360"
        synced_at: "2026-04-23T16:37:29Z"
---

Add testing, closures, access, conditions, generics, declarations, types, literals, idioms groups.

- [x] Add 9 new group keys to ConfigurationGroup
- [x] Create subdirectories and move rule files
- [x] Add group overrides to all affected rules (46 rules + 2 pre-existing fixes)
- [x] Add group overrides to 5 ungrouped layout settings
- [x] Verify build


## Summary of Changes

Added 9 new configuration groups (testing, closures, access, conditions, generics, declarations, types, literals, idioms) to ConfigurationGroup. Moved 46 syntax rules into group subdirectories with group overrides. Added group overrides to 5 layout settings. Fixed 2 pre-existing rules (NoEmptyLinesOpeningClosingBraces, NoLabelsInCasePatterns) that were in group directories but missing their group override. Grouped percentage: 52% → 90% (115/128 rules).
