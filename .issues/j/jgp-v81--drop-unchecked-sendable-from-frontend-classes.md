---
# jgp-v81
title: Drop @unchecked Sendable from Frontend classes
status: completed
type: task
priority: normal
created_at: 2026-04-25T20:42:07Z
updated_at: 2026-04-25T21:10:12Z
parent: 0ra-lks
sync:
    github:
        issue_number: "438"
        synced_at: "2026-04-25T22:35:13Z"
---

Three frontend classes are marked `@unchecked Sendable`. Their *state* (let / Mutex-protected) is fine, but the structural Swift 6 rules prevent dropping the annotation cleanly — see resolution below.

## Findings

- [ ] `Sources/Swiftiomatic/Frontend/Frontend.swift:19` — kept `@unchecked Sendable`. Cannot drop: `Frontend` is non-final (subclassed by `FormatFrontend` / `LintFrontend`), and Swift 6 requires non-final classes use `@unchecked Sendable` because subclass state can't be verified.
- [x] `Sources/Swiftiomatic/Frontend/FormatFrontend.swift:19` — added `final`. Still must restate `@unchecked Sendable` (Swift 6 warning: "Class must restate inherited '@unchecked Sendable' conformance").
- [x] `Sources/Swiftiomatic/Frontend/LintFrontend.swift:19` — added `final`. Same reason.

The 165 rule classes that inherit from `SyntaxVisitor` likewise cannot drop `@unchecked` because the visitor base has mutable walk state — out of scope here.

## Verification
- [x] Build clean.

## Summary of Changes

Added `final` to `FormatFrontend` and `LintFrontend`. The original ask (drop `@unchecked Sendable` entirely) is structurally blocked: `Frontend` is intentionally non-final so the format/lint subclasses can override `processFile`, and Swift 6 forbids non-final classes from conforming to plain `Sendable`. Subclasses must restate `@unchecked Sendable` even when their own state is empty/immutable.

Net improvement: the two leaf frontends are now explicitly `final`, signalling that further subclassing is not intended. To eliminate `@unchecked` entirely would require a larger refactor (convert `Frontend` to a protocol + struct/value-types, or move the override hook to a stored closure). Tracking that as a follow-up if it ever becomes important.
