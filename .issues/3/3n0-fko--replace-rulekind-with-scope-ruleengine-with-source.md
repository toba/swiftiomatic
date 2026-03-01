---
# 3n0-fko
title: Replace RuleKind with Scope, RuleEngine with Source
status: completed
type: task
priority: normal
created_at: 2026-03-01T00:48:26Z
updated_at: 2026-03-01T01:00:00Z
---

- [x] Rename RuleEngine → Source (enum + field)
- [x] Replace RuleKind with Scope enum
- [x] Drop category from output types
- [x] Update TextFormatter grouping
- [x] Update CLI quiet-mode
- [x] Update RuleDocumentation
- [x] Update ~265 rule descriptions
- [x] Update list-rules CLI
- [x] Update CLAUDE.md JSON example
- [x] Fix tests
- [x] Build and test


## Summary of Changes

- Renamed `RuleEngine` enum → `Source` with `displayName` property, renamed `engine` field → `source` across all types
- Replaced `RuleKind` (8 category values) with `Scope` enum (lint/format/suggest), added to `RuleDescription` with default `.lint`
- Deleted `RuleKind.swift`, created `Scope.swift`
- Removed `category` field from `Diagnostic` and `RuleCatalog.Entry`
- Updated `TextFormatter` to group by `Source` instead of `RuleKind`
- Updated CLI quiet-mode, list-rules `--source` flag, and `RuleDocumentation`
- Updated all ~261 rule descriptions (258 defaulting to `.lint`, 3 with explicit `scope: .suggest`)
- Updated test helpers and `DiagnosticFormatterTests`
- Updated CLAUDE.md JSON example
