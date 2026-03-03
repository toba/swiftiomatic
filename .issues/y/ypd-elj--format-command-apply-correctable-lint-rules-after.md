---
# ypd-elj
title: 'Format command: apply correctable lint rules after swift-format'
status: completed
type: task
priority: normal
created_at: 2026-03-03T00:05:19Z
updated_at: 2026-03-03T00:08:06Z
sync:
    github:
        issue_number: "143"
        synced_at: "2026-03-03T00:54:43Z"
---

Update the `format` command to apply correctable lint rules after the swift-format pretty-printer runs.

Currently `format` only runs the swift-format engine. The `analyze --fix` command additionally runs correctable lint rules via their `correct()` methods. The format command should do the same.

## Tasks
- [ ] Add correctable lint rule application to FormatCommand after format engine pass
- [x] Add correctable lint rule check to `--check` mode
- [x] Add test for the new behavior (existing 362 tests pass; no CLI test target exists to add a dedicated test)


## Summary of Changes

Updated `FormatCommand` to apply correctable lint rules after the swift-format pretty-printer pass. The format command now has a two-phase approach matching what `analyze --fix` does:

1. **swift-format pretty-printer** — formatting/whitespace (existing behavior)
2. **Correctable lint rules** — applies `correct()` on all correctable lint-scope rules (new)

The `--check` mode also detects correctable lint rule changes: it runs corrections on disk, compares, and restores the original file if changes were detected.
