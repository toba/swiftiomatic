---
# tf8-5aq
title: 'Release workflow fails: macos-15 runner lacks Swift 6.3 / Xcode 26'
status: completed
type: bug
priority: high
created_at: 2026-04-11T19:15:12Z
updated_at: 2026-04-11T19:19:56Z
sync:
    github:
        issue_number: "190"
        synced_at: "2026-04-11T19:22:39Z"
---

## Problem

The Release GitHub Actions workflow has failed on the last 3 tags (v0.18.4, v0.19.0, v0.20.0) with:

```
error: 'swiftiomatic': package 'swiftiomatic' is using Swift tools version 6.3.0
but the installed version is 6.2.4
```

## Root Cause

`.github/workflows/release.yml` line 10 uses `runs-on: macos-15`, and line 16 tries to select `Xcode_26.3.app` — but `macos-15` runners only ship Xcode 16.x (Swift 6.2.x). Xcode 26 (Swift 6.3) requires the `macos-26` runner image.

This broke when `swift-tools-version` was bumped to 6.3 in commit 6c25b91.

## Fix

- [x] Change `runs-on: macos-15` → `runs-on: macos-26` in `.github/workflows/release.yml`
- [x] Verify the Xcode select path (`Xcode_26.3.app`) matches what's installed on `macos-26` runners (check runner readme)
- [x] Update Homebrew formula `depends_on :macos` from `:sequoia` to `:tahoe` since macOS 26 is Tahoe
- [ ] Re-tag v0.20.0 (or create v0.20.1) to trigger a successful release


## Summary of Changes

Fixed `runs-on: macos-15` → `runs-on: macos-26` and Homebrew formula `:sequoia` → `:tahoe`. Tagged v0.21.0 — push to trigger release.
