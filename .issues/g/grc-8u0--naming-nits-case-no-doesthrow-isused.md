---
# grc-8u0
title: 'Naming nits: case no, doesThrow, isUsed'
status: completed
type: task
priority: low
created_at: 2026-04-25T20:43:43Z
updated_at: 2026-04-25T22:24:41Z
parent: 0ra-lks
sync:
    github:
        issue_number: "425"
        synced_at: "2026-04-25T22:35:10Z"
---

Small naming improvements aligned with API design guidelines.

## Findings

- [ ] `Lint.no` → `.off`: deferred. The rename touches 70+ source files and existing user `swiftiomatic.json` configs (every `"lint": "no"`). Worth doing only as a coordinated breaking-change pass, not bundled into a low-priority cleanup. Left as future work.
- [x] Renamed `doesThrow` → `hasThrow` in `UnhandledThrowingTask.swift` (visitor-internal flag; no external callers)
- [x] Renamed `isUsed` → `wasUsed` in `UnusedSetterValue.swift` (visitor-internal flag)
- [ ] `-able`-suffix protocol audit: deferred. The protocol vocabulary (`Configurable`, `BracedSyntax`, `SyntaxProtocol`, `Sendable`, `Codable`, `Equatable`, `Hashable`, `Comparable`, `Sequence`/`Collection` family) is mostly inherited from Swift stdlib / SwiftSyntax conventions where `-able` describes a capability rather than an action. No clear `-ing` candidates surfaced in a spot check.

## Test plan
- [ ] Rename mechanical; existing tests pass


## Summary of Changes

- Renamed visitor-internal flags `doesThrow` → `hasThrow` and `isUsed` → `wasUsed` (file-local; no external callers).
- Deferred two cross-cutting renames — the `Lint.no` → `.off` rename is too disruptive to bundle here (70+ source-file change + user-config breaking change), and the `-able` protocol audit found no clean candidates (most names follow stdlib / SwiftSyntax conventions).
- All 2795 tests pass.
