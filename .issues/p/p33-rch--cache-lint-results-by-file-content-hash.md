---
# p33-rch
title: Cache lint results by file content hash
status: in-progress
type: feature
priority: high
created_at: 2026-04-30T04:15:35Z
updated_at: 2026-04-30T04:23:11Z
sync:
    github:
        issue_number: "526"
        synced_at: "2026-04-30T04:23:37Z"
---

## Problem

`sm lint --parallel --recursive Sources/SwiftiomaticKit` takes ~7s wall / ~46s CPU on every invocation, even when nothing changed. This dominates Xcode build wall-time when the prebuild lint plugin is attached, and is the root cause of why the plugin had to be removed from `SwiftiomaticKit` in the working tree.

Per-file cost is ~22ms × 305 files. Startup is negligible (~12ms). So the work is genuinely 'lint every file every time'.

## Proposal

Cache lint findings keyed by file content hash (and a 'lint engine fingerprint' that invalidates the whole cache when rules change).

- Cache location: `.build/sm-lint-cache/` (or `~/Library/Caches/sm/<project-hash>/`).
- Key per file: SHA256 of file contents + engine fingerprint.
- Value: list of findings (or empty for clean).
- On lint: hash file → if cache hit, replay cached findings; else lint, store result.
- Engine fingerprint: hash of rule list + rule version + configuration. Bump on any rule change to force re-lint.

## Expected impact

- No-change run: ~0.05s (just hash 305 files).
- 1–2 changed files: ~0.2s.
- Cache miss after rule change: same as today (~7s) — one-time cost.

This unblocks re-attaching the prebuild lint plugin to `SwiftiomaticKit` (currently removed for build-speed reasons — see wpg-h5c).

## Open questions

- Where to put the cache (per-project `.build` vs user cache dir).
- Should the cache be shared between `sm format` and `sm lint`?
- How to invalidate when configuration changes mid-session.
- Whether to cache fixits/format rewrites too (probably out of scope for v1).

## References

- wpg-h5c — Speed up swift package test wall-time: prebuild lint plugin dominates
