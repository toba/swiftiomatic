---
# bqt-jfy
title: 'Unify comment prefix to sm: and clean up Configuration'
status: completed
type: task
priority: normal
created_at: 2026-02-28T17:05:59Z
updated_at: 2026-02-28T17:16:33Z
---

Replace all inline comment prefixes:
- `swiftlint:` → `sm:` (lint engine)
- `swiftformat:` → `sm:` (format engine)

Rename InvalidSwiftLintCommandRule → InvalidCommandRule, update AllRules.swift.
Update Configuration.defaultFileName to `.swiftiomatic.yaml`.
Recalculate CommandTests ranges (7 chars shorter).

- [x] Core parsing (CommandVisitor, Command, SwiftSource+Cache)
- [x] Format engine (Formatter.swift)
- [x] Format rules with directive matching
- [x] Lint rules with hardcoded prefix (InvalidCommand rename, BlanketDisable, Superfluous)
- [x] FileHeaderRule
- [x] Inline pragmas in source files
- [x] Tests — CommandTests range recalculation
- [x] Tests — remaining test files
- [x] Configuration cleanup
- [x] Build verification
- [x] Test verification


## Summary of Changes

Unified all inline comment prefixes to `sm:` across the entire codebase:
- `swiftlint:` → `sm:` (core parsing, 56 source files, all lint rules)
- `swiftformat:` → `sm:` (format engine, 5 source files)
- Renamed `InvalidSwiftLintCommandRule` → `InvalidCommandRule` (identifier: `invalid_command`)
- Updated `Configuration.defaultFileName` to `.swiftiomatic.yaml`
- Recalculated all hardcoded ranges in CommandTests (-7 chars)
- Updated all test files (~240 occurrences)
- Build passes, all tests pass (0 failures)
