---
# t7v-e5m
title: Default lint to recursive directory walk
status: completed
type: feature
priority: normal
created_at: 2026-05-08T15:07:04Z
updated_at: 2026-05-08T15:16:22Z
sync:
    github:
        issue_number: "659"
        synced_at: "2026-05-08T15:45:10Z"
---

Currently `sm lint` (and `sm format`) require explicit file paths. When invoked without arguments, or with a directory argument, it should recursively lint all Swift files under the current working directory (or given directory) by default — matching the ergonomics of `swift-format` with `--recursive` and tools like `ruff`/`eslint`.

## Motivation

Agentic workflows and humans both routinely want to lint the whole project. Forcing callers to enumerate paths (or remember `--recursive .`) leads to incomplete linting and missed issues. The common case should be the default.

## Proposal

- `sm lint` with no positional args → recurse from cwd
- `sm lint <dir>` → recurse from `<dir>`
- `sm lint <file.swift> ...` → lint listed files (current behavior)
- Same treatment for `sm format`
- Respect `.gitignore` and any existing exclude config

## Notes

Discovered while running sm in the thesis project; the agent linted only modified files and missed thousands of pre-existing issues across the tree.


## Summary of Changes

- New `resolveInputs(rawPaths:stdinIsTTY:)` helper in `SwiftiomaticKit` (Sources/SwiftiomaticKit/Syntax/InputResolution.swift) returns `.stdin` for `["-"]`, defaults to recursing cwd when no paths are given and stdin is a TTY, falls back to stdin when stdin is piped, and otherwise returns the explicit URL list.
- `Frontend.run()` (Sources/Swiftiomatic/Frontend/Frontend.swift) now uses the helper, replacing the deprecation warning when no paths are given. `FileIterator` already auto-recurses any directory URL, so explicit `--recursive` is no longer required for `lint`/`format`.
- `LintFormatOptions.validate()` (Sources/Swiftiomatic/Subcommands/LintFormatOptions.swift) drops the "directory needs --recursive" and "--recursive without paths" errors. `--recursive` is preserved as a no-op flag for back-compat with Xcode invocations.
- `Format.validate()` (Sources/Swiftiomatic/Subcommands/Format.swift) now requires `--in-place` when the invocation would recurse a directory tree (explicit dir argument, or empty paths with a TTY stdin), to prevent dumping concatenated file contents to stdout.
- New tests in Tests/SwiftiomaticTests/Utilities/InputResolutionTests.swift cover the four resolution branches.
