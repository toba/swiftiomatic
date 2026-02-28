---
# bqt-jfy
title: 'Unify comment prefix to sm: and clean up Configuration'
status: in-progress
type: task
created_at: 2026-02-28T17:05:59Z
updated_at: 2026-02-28T17:05:59Z
---

Replace all inline comment prefixes:
- `swiftlint:` → `sm:` (lint engine)
- `swiftformat:` → `sm:` (format engine)

Rename InvalidSwiftLintCommandRule → InvalidCommandRule, update AllRules.swift.
Update Configuration.defaultFileName to `.swiftiomatic.yaml`.
Recalculate CommandTests ranges (7 chars shorter).

- [ ] Core parsing (CommandVisitor, Command, SwiftLintFile+Cache)
- [ ] Format engine (Formatter.swift)
- [ ] Format rules with directive matching
- [ ] Lint rules with hardcoded prefix (InvalidCommand rename, BlanketDisable, Superfluous)
- [ ] FileHeaderRule
- [ ] Inline pragmas in source files
- [ ] Tests — CommandTests range recalculation
- [ ] Tests — remaining test files
- [ ] Configuration cleanup
- [ ] Build verification
- [ ] Test verification
