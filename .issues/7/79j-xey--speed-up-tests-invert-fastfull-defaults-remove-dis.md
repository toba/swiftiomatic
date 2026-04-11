---
# 79j-xey
title: 'Speed up tests: invert fast/full defaults, remove disk I/O from correction tests'
status: completed
type: task
priority: normal
created_at: 2026-04-11T20:54:04Z
updated_at: 2026-04-11T20:56:32Z
sync:
    github:
        issue_number: "195"
        synced_at: "2026-04-11T21:07:03Z"
---

## Problem

The test suite (~1,948 cases) is slow because each rule example test runs 6+ variant checks (emoji, shebang, comment, string, disable command, severity) by default. Correction tests also write temporary files to disk unnecessarily.

## Tasks

- [x] Invert fast/full test defaults: change `SWIFTIOMATIC_FAST_TESTS` (opt-in fast) to `SWIFTIOMATIC_FULL_TESTS` (opt-in slow)
- [x] Set `SWIFTIOMATIC_FULL_TESTS=1` in release CI workflow
- [x] Remove `persistToDisk: true` from correction test helpers (use virtual in-memory files)
- [x] Run tests to verify


## Summary of Changes

- Inverted fast/full test default: variant tests (emoji, shebang, comment, string, disable, severity) now skip by default; set `SWIFTIOMATIC_FULL_TESTS=1` for full coverage
- Release CI sets `SWIFTIOMATIC_FULL_TESTS=1` so variants still run before releases
- Correction tests use virtual in-memory files instead of writing to `/tmp`, eliminating thousands of filesystem operations
- Fast mode: 467 tests pass; full mode: 361 tests pass (both 0 failures)
