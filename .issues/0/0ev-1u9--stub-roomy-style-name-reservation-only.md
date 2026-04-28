---
# 0ev-1u9
title: Stub `roomy` style (name reservation only)
status: completed
type: task
priority: low
created_at: 2026-04-28T01:40:53Z
updated_at: 2026-04-28T02:19:50Z
parent: iv7-r5g
sync:
    github:
        issue_number: "485"
        synced_at: "2026-04-28T02:40:02Z"
---

## Goal

Reserve the `roomy` style name without implementing it. `roomy` is the "more vertical / more breathing room" counterpart to `compact`; the actual layout differences are deferred past `iv7-r5g`.

## Scope

- Add the `roomy` case to the `Style` enum.
- Selecting `roomy` either (a) errors with "not yet implemented — fall back to `compact` or omit `style`" or (b) emits a one-time warning and falls back to `compact`. Pick (a) — explicit failure is easier to remove later.
- Document the case in DocC and in any user-facing config reference.
- Tests: assert the case exists; assert the error path fires; assert it does **not** silently behave like `compact`.

## Out of scope

- Any actual layout differences between `roomy` and `compact`. That's a future epic.



## Summary of Changes

- `Style` enum already added in `o72-vx7` with both cases (`compact`, `roomy`).
- Added `SwiftiomaticError.styleNotImplemented(String)` case in `Sources/SwiftiomaticKit/Support/SwiftiomaticError.swift`.
- Added `Configuration.validateStyleSupported()` in new file `Sources/SwiftiomaticKit/Configuration/Configuration+Style.swift` — throws `.styleNotImplemented("roomy")` when `roomy` is selected.
- Wired validation into `RewriteCoordinator.format(source:...)` and `LintCoordinator.lint(source:...)` so format/lint fail fast at the central entry.
- Added `Tests/SwiftiomaticTests/API/StyleTests.swift` with 5 tests covering: default is compact, both cases exist, compact validates, roomy throws, JSON decoding round-trips. All pass.

### Notes

- Validation happens at format/lint time, not at config load. `dump-configuration` can still display `style: roomy` without erroring — explicit failure surfaces only when actually formatting/linting.
- DocC update deferred to `0we-lcr` (the dedicated docs issue).
