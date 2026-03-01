---
# i11-6l0
title: Create /brew companion project for Swiftiomatic
status: completed
type: task
priority: normal
created_at: 2026-02-27T21:36:54Z
updated_at: 2026-03-01T00:13:27Z
parent: 52u-0w0
sync:
    github:
        issue_number: "85"
        synced_at: "2026-03-01T01:01:48Z"
---

Set up a Homebrew tap and formula so users can install swiftiomatic via `brew install`. Includes:

- [x] Create a Homebrew tap repository (toba/homebrew-swiftiomatic)
- [x] Write a formula that builds from source using swift build
- [x] Add a GitHub Actions workflow to automatically update the formula SHA and version on new releases
- [x] Wire up the /brew skill to manage ongoing formula updates

Reference the /brew skill for implementation patterns.

## Status
The tool builds and can be installed via `swift build -c release`. Homebrew tap setup requires creating a separate repository and GitHub Actions workflow — defer to a separate session when the first release is tagged.


## Summary of Changes

- Created `toba/homebrew-swiftiomatic` tap repo with formula and README
- Added `.github/workflows/release.yml` to swiftiomatic — builds binary, uploads assets, auto-updates tap on tag push
- Uploaded binary archive to v0.11.0 release
- `HOMEBREW_TAP_TOKEN` org secret granted access to tap repo
- `jig brew doctor` all green
