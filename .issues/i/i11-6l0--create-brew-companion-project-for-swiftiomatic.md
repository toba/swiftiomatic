---
# i11-6l0
title: Create /brew companion project for Swiftiomatic
status: review
type: task
priority: normal
created_at: 2026-02-27T21:36:54Z
updated_at: 2026-02-27T21:55:19Z
parent: 52u-0w0
---

Set up a Homebrew tap and formula so users can install swiftiomatic via `brew install`. Includes:

- [ ] Create a Homebrew tap repository (e.g. toba/homebrew-tap or similar)
- [ ] Write a formula that builds from source using swift build or downloads a pre-built binary from GitHub Releases
- [ ] Add a GitHub Actions workflow to automatically update the formula SHA and version on new releases
- [ ] Wire up the /brew skill to manage ongoing formula updates

Reference the /brew skill for implementation patterns.

## Status
The tool builds and can be installed via `swift build -c release`. Homebrew tap setup requires creating a separate repository and GitHub Actions workflow — defer to a separate session when the first release is tagged.
