---
# lbt-zsc
title: 'Clean up Configuration: ConfigItem protocol, format rule modes, reduce duplication'
status: completed
type: feature
priority: normal
created_at: 2026-04-18T00:37:17Z
updated_at: 2026-04-18T15:59:28Z
sync:
    github:
        issue_number: "337"
        synced_at: "2026-04-23T05:30:24Z"
---

## Problem

Configuration.swift has significant duplication and lacks a unifying abstraction:

1. **FormatSettings duplicates every property 5 times** — property declaration, `init(from config:)`, `init(from decoder:)`, `apply(to:)`, `encode(into:)`, plus `keyNames` set
2. **8 rule config structs** follow identical boilerplate (defaults + decodeIfPresent pattern)
3. **Umbrella group decode/encode** has ad-hoc special cases for UpdateBlankLines and UpdateLineBreak
4. **Schema generation** hardcodes rule options in a switch statement
5. **No way to run format rules in lint-only mode** — RuleSeverity is warn/error/off, but format rules should support fix/warn/error/off

## Design Direction

### ConfigItem protocol
A protocol that unifies config items with a name, optional children, and associated value type. This would drive schema generation, encoding/decoding, and documentation from a single source of truth.

### Format rule modes
Extend RuleSeverity (or introduce a new type) so format rules can be configured as:
- `fix` — auto-format (run in FormatPipeline, rewrite + diagnose)
- `warn` — lint only (run in LintPipeline only, diagnose as warning)
- `error` — lint only (run in LintPipeline only, diagnose as error)
- `off` — disabled

Lint-only rules remain: warn/error/off (fix is invalid for them).

### Reduce FormatSettings duplication
Either code-generate or use a macro/reflection approach to eliminate the 5x property duplication.

## Tasks

- [x] Design ConfigItem protocol hierarchy
- [x] Add `fix` case — renamed RuleSeverity → RuleHandling with fix/warn/error/off
- [x] Wire fix/warn/error distinction — added shouldFix() to Context
- [x] Reduce FormatSettings boilerplate — replaced with FormatSetting table
- [x] Update group handling — ConfigGroup enum + Groupable protocol
- [x] Update ConfigurationSchemaGenerator — flat root, mode key, fix values
- [x] Update tests — all 2349 pass
- [x] Update swiftiomatic.json — migrated to v4 format


## Summary of Changes

- Renamed `RuleSeverity` → `RuleHandling` with new `.fix` case for format rules
- Created `ConfigGroup` enum and `Groupable` protocol; Rule protocol inherits Groupable
- Added `group` overrides to 38 grouped rules
- Replaced 5x-duplicated `FormatSettings` struct with closure-based `FormatSetting` table
- Unified JSON config: flat root with settings, rules, and groups at same level (v4)
- JSON key `severity` → `mode`; format rules default to `fix`
- Added `shouldFix()` to Context for future FormatPipeline gating
- Updated schema generator, registry generator, tests, and swiftiomatic.json
- All 2349 tests pass
