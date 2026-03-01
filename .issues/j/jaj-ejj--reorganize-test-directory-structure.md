---
# jaj-ejj
title: Reorganize test directory structure
status: completed
type: task
priority: normal
created_at: 2026-02-28T23:54:24Z
updated_at: 2026-03-01T00:13:05Z
sync:
    github:
        issue_number: "53"
        synced_at: "2026-03-01T01:01:38Z"
---

Reorganize Tests/SwiftiomaticTests/ to mirror Sources/Swiftiomatic/ folder structure.

## Requirements
- Top-level test folders should match top-level source folders
- Sub-folders can be thematic
- No folders with just 1-2 files
- No folders with 50+ files

## Tasks
- [x] Map current test files to new locations
- [x] Move files to new structure
- [x] Verify build succeeds


## Summary of Changes

Reorganized Tests/SwiftiomaticTests/ to mirror Sources/Swiftiomatic/ top-level structure:

**Top-level folders (matching Sources/):**
- Configuration/ (7 tests + ConfigFixtures/)
- Extensions/ (5 tests)
- Format/ (24 tests, renamed from FormatTests/)
- Models/ (5 tests)
- Rules/ (258 tests across 14 thematic sub-folders + Resources/)
- Suggest/ (4 tests + SuggestFixtures/)
- Support/ (13 test helpers)

**Rules/ sub-folders (thematic groupings, all 3-50 files):**
Spacing (25), LineFormatting (31), Wrapping (20), Redundancy (47), Naming (13), Ordering (23), TypeSafety (19), ControlFlow (17), Metrics (10), DeadCode (8), Testing (11), Frameworks (6), AccessControl (4), Documentation (5), Infrastructure (19 + Generated/)

Updated Package.swift resource paths and TestResources.path() logic.
