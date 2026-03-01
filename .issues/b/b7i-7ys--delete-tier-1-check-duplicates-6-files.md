---
# b7i-7ys
title: Delete Tier 1 Check duplicates (6 files)
status: completed
type: task
priority: normal
created_at: 2026-02-28T17:05:21Z
updated_at: 2026-02-28T17:25:11Z
parent: dz8-axs
blocked_by:
    - qjw-hor
sync:
    github:
        issue_number: "74"
        synced_at: "2026-03-01T01:01:43Z"
---

Six Check types have identical detection logic to their paired Rule. Delete the Check files — the Rules already cover everything.

## Delete these files

- [ ] `Rules/Suggest/AgentReviewCheck.swift`
- [ ] `Rules/Suggest/FireAndForgetTaskCheck.swift`
- [ ] `Rules/Suggest/PerformanceAntiPatternsCheck.swift`
- [ ] `Rules/Suggest/Swift62ModernizationCheck.swift`
- [ ] `Rules/Suggest/SwiftUILayoutCheck.swift`
- [ ] `Rules/Suggest/ObservationPitfallsCheck.swift`

## Also update

- [ ] `Analyzer.makeChecks()` — remove instantiation of deleted checks
- [ ] Verify the corresponding Rules are in `AllRules.swift`
- [ ] Build and test
