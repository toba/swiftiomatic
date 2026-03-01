---
# dz8-axs
title: 'Organize rules: merge Check→Rule + rebalance folders'
status: completed
type: epic
priority: normal
created_at: 2026-02-28T16:42:39Z
updated_at: 2026-02-28T17:53:21Z
sync:
    github:
        issue_number: "40"
        synced_at: "2026-03-01T01:01:36Z"
---

## Problem

Two organizational issues in the rules codebase:

### 1. Inconsistent naming: Check vs Rule

The Suggest/ subfolder has paired types — a `BaseCheck` subclass (e.g. `AgentReviewCheck`) and a SwiftLint-compatible Rule facade (e.g. `AgentReviewRule`). Two checks live in their own top-level folders with only 1 file each:
- `Concurrency/ConcurrencyModernizationRule` ↔ `Suggest/ConcurrencyModernizationCheck`
- `Observation/ObservationPitfallsRule` ↔ `Suggest/ObservationPitfallsCheck`

Decision needed: standardize on one suffix, or keep the dual-naming with a clear convention.

### 2. Uneven folder sizes

Current file counts (Rules/ subfolders):

| Folder | Files | Notes |
|--------|------:|-------|
| Concurrency | 1 | Single rule |
| Observation | 1 | Single rule |
| Metrics | 12 | 10 rules + 2 examples |
| Performance | 14 | 14 rules |
| Suggest | 25 | 10 rules + 13 checks + protocols |
| RuleConfigurations | 81 | Config structs (support, keep separate) |
| Idiomatic | 87 | 76 rules + 11 examples |
| Lint | 95 | 72 rules + 23 examples |
| Style | 102 | 76 rules + 26 examples |
| Format | 138 | Token-based engine (separate, keep as-is) |

Idiomatic/Lint/Style are 87-102 files each while Concurrency/Observation have 1 file each. Goal: ~20-30 rule files per folder.

## Plan

Two-part effort:
1. **Merge Check→Rule** — eliminate Check/BaseCheck/Finding infrastructure; each suggest feature becomes a single Rule
2. **Rebalance folders** — reorganize ~320 files from 8 uneven folders into ~13 themed folders of 20–30 files each

See sub-tasks for detailed steps.
