---
# lbg-zcb
title: 'Fix CI warnings: update GitHub Actions to Node.js 24-native versions'
status: completed
type: task
priority: normal
created_at: 2026-04-24T21:38:23Z
updated_at: 2026-04-24T21:39:41Z
sync:
    github:
        issue_number: "379"
        synced_at: "2026-04-24T21:41:01Z"
---

## Problem

The release workflow produces several warnings on every run:

1. **Node.js 20 deprecation** — `actions/cache@v4`, `actions/checkout@v4`, and `softprops/action-gh-release@v2` target Node.js 20 (EOL). Currently forced to Node 24 via `FORCE_JAVASCRIPT_ACTIONS_TO_NODE24: true` env var.
2. **DEP0040** — `punycode` module is deprecated (use a userland alternative)
3. **DEP0169** — `url.parse()` behavior not standardized (use WHATWG URL API)

Warnings 2 and 3 are side effects of running Node 20-era actions on Node 24.

## Fix

- [x] Update `actions/checkout` from `v4` → `v6` (Node 24 native) in both `ci.yml` and `release.yml`
- [x] Update `actions/cache` from `v4` → `v5` (Node 24 native) in both `ci.yml` and `release.yml`
- [x] Update `softprops/action-gh-release` from `v2` → `v3` (Node 24 native) in `release.yml`
- [x] Remove `FORCE_JAVASCRIPT_ACTIONS_TO_NODE24: true` env var from both workflows
- [x] Verify no other actions need updating

## Files

- `.github/workflows/ci.yml`
- `.github/workflows/release.yml`


## Summary of Changes

Updated all GitHub Actions to Node.js 24-native versions:
- `actions/checkout` v4 → v6
- `actions/cache` v4 → v5
- `softprops/action-gh-release` v2 → v3
- Removed `FORCE_JAVASCRIPT_ACTIONS_TO_NODE24` workaround from both workflows

This eliminates the Node.js 20 deprecation warning and the `punycode`/`url.parse()` deprecation warnings.
