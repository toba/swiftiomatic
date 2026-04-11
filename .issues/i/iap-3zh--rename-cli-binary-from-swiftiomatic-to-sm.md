---
# iap-3zh
title: Rename CLI binary from swiftiomatic to sm
status: completed
type: task
priority: normal
created_at: 2026-04-11T20:31:31Z
updated_at: 2026-04-11T20:34:37Z
sync:
    github:
        issue_number: "192"
        synced_at: "2026-04-11T20:48:50Z"
---

Rename only the executable binary — not types, targets, folders, or config file names.

- [x] Package.swift executable product name
- [x] Plugin tool references
- [x] GitHub Actions release workflow (build, archive, Homebrew formula)
- [x] scripts/install.sh
- [x] README.md command examples
- [x] CLAUDE.md command examples


## Summary of Changes

Renamed CLI binary from `swiftiomatic` to `sm`. Updated Package.swift product name, SPM plugin tool lookups, GitHub Actions release workflow (archive names, Homebrew formula class/file/install), install script, README, and CLAUDE.md. No types, targets, folders, or config file names were changed.
