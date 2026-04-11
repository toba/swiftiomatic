---
# cf4-jj5
title: Setup brew installation within existing toba tap
status: completed
type: task
priority: normal
created_at: 2026-04-11T01:19:10Z
updated_at: 2026-04-11T01:19:55Z
sync:
    github:
        issue_number: "171"
        synced_at: "2026-04-11T01:32:19Z"
---

- [x] Check existing toba/homebrew-tap repo — formula already exists at Formula/swiftiomatic.rb
- [x] Fix release.yml to clone toba/homebrew-tap instead of toba/homebrew-swiftiomatic
- [x] Add companions.brew config to .jig.yaml


## Summary of Changes

Fixed release workflow to use existing `toba/homebrew-tap` repo and added `companions.brew` config to `.jig.yaml`.
