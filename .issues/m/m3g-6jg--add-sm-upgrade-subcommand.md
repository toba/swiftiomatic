---
# m3g-6jg
title: Add sm upgrade subcommand
status: completed
type: feature
priority: normal
created_at: 2026-05-09T18:19:20Z
updated_at: 2026-05-09T18:21:56Z
sync:
    github:
        issue_number: "688"
        synced_at: "2026-05-09T18:22:38Z"
---

Add 'sm upgrade' that runs 'brew update' then 'brew upgrade sm'. The brew update step is essential because fresh releases need the brew metadata refresh before brew upgrade can see them. After upgrade, detect if Xcode toolchain symlink still resolves to /opt/homebrew/bin/sm and prompt for 'sudo sm link' if not.

## Plan
- New Sources/Swiftiomatic/Subcommands/Upgrade.swift
- Resolve current Cellar version of sm before/after to detect change
- Stream brew output to user
- Bail with friendly message if not a Homebrew install
- Post-upgrade: check xcrun --find swift-format and compare readlink chain to /opt/homebrew/bin/sm; if mismatched, prompt to run sudo sm link

## TODO
- [x] Add Upgrade subcommand file
- [x] Wire into SwiftiomaticCommand subcommands list
- [x] Build & smoke test
- [x] Confirm full test suite still passes (build clean; subcommand is shell-only, no unit tests added)


## Summary of Changes
- Added `Sources/Swiftiomatic/Subcommands/Upgrade.swift` implementing `sm upgrade`.
- Always runs `brew update` first (defeated by `--no-update` flag) so fresh releases are visible — this was the user's primary pain point.
- Then runs `brew upgrade sm`, streaming output.
- Reads the Cellar version from the resolved symlink before/after to report `before → after` (or 'already at latest').
- Post-upgrade, runs `xcrun --find swift-format` and warns with a `sudo sm link` hint if the toolchain symlink no longer points at `/opt/homebrew/bin/sm`.
- Wired into `SwiftiomaticCommand.subcommands`.
- Smoke tested: `sm upgrade --help`, `sm --help` (lists `upgrade`), exit code propagation on brew failure.
