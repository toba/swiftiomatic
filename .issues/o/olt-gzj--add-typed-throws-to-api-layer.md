---
# olt-gzj
title: Add typed throws to API layer
status: completed
type: task
priority: high
created_at: 2026-04-14T02:41:43Z
updated_at: 2026-04-14T02:57:00Z
parent: kqx-iku
sync:
    github:
        issue_number: "277"
        synced_at: "2026-04-14T02:58:31Z"
---

All public throwing functions in the API layer throw only `SwiftiomaticError` but declare untyped `throws`. Convert to `throws(SwiftiomaticError)`.

## Files
- `Sources/Swiftiomatic/API/SwiftiomaticFormatter.swift` — 3 functions (lines 57, 101, 152)
- `Sources/Swiftiomatic/API/SwiftiomaticLinter.swift` — 3 functions (lines 55, 91, 133)
- `Sources/Swiftiomatic/API/Configuration.swift` — `asJsonString()` (line 17)
- `Sources/Swiftiomatic/Core/Parsing.swift` — `parseAndEmitDiagnostics()` (line 39)

## Also check CLI layer
- `Sources/sm/VersionOptions.swift` — `validate()` (line 20)
- `Sources/sm/Frontend/ConfigurationLoader.swift` — lines 28, 39
- `Sources/sm/Subcommands/DumpConfiguration.swift` — lines 36, 42
- `Sources/sm/Subcommands/Format.swift` — line 44
- `Sources/sm/Subcommands/Lint.swift` — line 35

Note: `Configuration.init(from decoder:)` throws `DecodingError` (protocol requirement) — leave untyped.

## Tasks
- [x] Convert API layer functions to `throws(SwiftiomaticError)`
- [x] Convert CLI layer functions where single error type (N/A — CLI throws ExitCode/ValidationError, not SwiftiomaticError)
- [x] Verify callers handle typed throws correctly
- [x] Build and test


## Summary of Changes

Converted 9 functions to `throws(SwiftiomaticError)`:
- `parseAndEmitDiagnostics()` in Parsing.swift
- `Configuration.asJsonString()` in Configuration+Dump.swift
- `SwiftiomaticFormatter.format(contentsOf:...)`, `format(source:...)`, `format(syntax:...)` — wrapped `String(contentsOf:)` in do-catch converting to `.fileNotReadable`
- `SwiftiomaticLinter.lint(contentsOf:...)`, `lint(source:...)`, `lint(syntax:...)` (public + private) — same wrapping pattern

CLI layer functions skipped: they throw `ExitCode`/`ValidationError` (ArgumentParser types), not `SwiftiomaticError`.

All 2715 tests pass.
