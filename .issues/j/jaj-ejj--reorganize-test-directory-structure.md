---
# jaj-ejj
title: Reorganize test directory structure
status: in-progress
type: task
created_at: 2026-02-28T23:54:24Z
updated_at: 2026-02-28T23:54:24Z
---

Reorganize Tests/SwiftiomaticTests/ to mirror Sources/Swiftiomatic/ folder structure.

## Requirements
- Top-level test folders should match top-level source folders
- Sub-folders can be thematic
- No folders with just 1-2 files
- No folders with 50+ files

## Tasks
- [ ] Map current test files to new locations
- [ ] Move files to new structure
- [ ] Verify build succeeds
