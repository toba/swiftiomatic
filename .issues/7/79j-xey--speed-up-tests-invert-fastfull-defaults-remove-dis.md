---
# 79j-xey
title: 'Speed up tests: invert fast/full defaults, remove disk I/O from correction tests'
status: in-progress
type: task
created_at: 2026-04-11T20:54:04Z
updated_at: 2026-04-11T20:54:04Z
---

## Problem

The test suite (~1,948 cases) is slow because each rule example test runs 6+ variant checks (emoji, shebang, comment, string, disable command, severity) by default. Correction tests also write temporary files to disk unnecessarily.

## Tasks

- [ ] Invert fast/full test defaults: change `SWIFTIOMATIC_FAST_TESTS` (opt-in fast) to `SWIFTIOMATIC_FULL_TESTS` (opt-in slow)
- [ ] Set `SWIFTIOMATIC_FULL_TESTS=1` in release CI workflow
- [ ] Remove `persistToDisk: true` from correction test helpers (use virtual in-memory files)
- [ ] Run tests to verify
