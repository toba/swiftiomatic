---
# kbg-508
title: 'Config umbrellas: UpdateBlankLines and RemoveRedundant as config-only groups over individual rules'
status: completed
type: feature
priority: normal
created_at: 2026-04-17T23:17:55Z
updated_at: 2026-04-17T23:57:02Z
sync:
    github:
        issue_number: "324"
        synced_at: "2026-04-23T05:30:22Z"
---

## Tasks

- [x] Consolidate 7 BlankLines* rules into single UpdateBlankLines rule with per-location config
- [x] Add UpdateBlankLinesConfiguration to Configuration.swift
- [x] Wire config into ruleConfigDecoders, ruleConfigEncodable, schema generator
- [x] Create UpdateBlankLinesTests consolidating 7 test files
- [x] Move Redundant* (23), Wrap* (6), Sort* (4), Hoist* (2) into subdirectories
- [x] Mirror test subdirectories
- [x] Regenerate pipelines, update swiftiomatic.json
- [x] Build and test


## Revised Approach\n\nRevert UpdateBlankLines rule consolidation. Keep all 30 rules as separate classes for pipeline efficiency. Instead, create config-only umbrellas: UpdateBlankLines and RemoveRedundant group sub-options in the JSON config, expanding into individual rule entries internally. Move maximumBlankLines into UpdateBlankLines.\n\n## Summary of Changes

Consolidated 7 BlankLines* rules into single `UpdateBlankLines` format rule with per-location config options (`"add"`, `"remove"`, or `false`). Moved 35 format rules into 4 subdirectories: `Redundant/` (23), `Wrap/` (6), `Sort/` (4), `Hoist/` (2). All 2345 tests pass.



Reverted UpdateBlankLines rule consolidation — individual BlankLines* and Redundant* rules kept as separate classes for pipeline efficiency. Config umbrellas decode/encode as grouped objects in JSON, expanding internally to individual rule entries. maximumBlankLines moved from top-level format settings into UpdateBlankLines umbrella. All 2348 tests pass.
