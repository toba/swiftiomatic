---
# y14-fus
title: Add test job to CI; gate Homebrew update on tests passing
status: completed
type: task
priority: high
created_at: 2026-04-11T19:19:58Z
updated_at: 2026-04-11T19:21:21Z
sync:
    github:
        issue_number: "191"
        synced_at: "2026-04-11T19:22:39Z"
---

## Problem

The Release workflow builds and publishes without running the test suite. If a release has broken tests, it still ships to Homebrew.

## Fix

- [x] Add a `test` job to `.github/workflows/release.yml` that runs the test suite on `macos-26`
- [x] Make the `build` job depend on `test` via `needs: test`
- [x] The `update-homebrew` job already depends on `build`, so the chain becomes: test → build → update-homebrew


## Summary of Changes

Added `test` job to release workflow that runs the test suite before building. Build job now has `needs: test` so failures gate the release.
