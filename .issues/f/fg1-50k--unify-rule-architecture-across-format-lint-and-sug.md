---
# fg1-50k
title: Unify rule architecture across Format, Lint, and Suggest
status: completed
type: epic
priority: normal
created_at: 2026-02-28T00:40:27Z
updated_at: 2026-02-28T00:57:37Z
sync:
    github:
        issue_number: "50"
        synced_at: "2026-03-01T01:01:38Z"
---

Converge three subsystems into one rule framework. Lint's framework becomes THE rule framework. Suggest checks get ported as Lint rules. Format keeps its engine but integrates at registration/CLI level.

## Phases
- [ ] Phase 1: Restructure folders (lift Core/ and Rules/ to top level)
- [ ] Phase 2: Extend Core models for Suggest-grade output
- [ ] Phase 3: Port Suggest rules as Lint rules
- [ ] Phase 4: Delete Suggest framework + wire CLI
- [ ] Phase 5: Dedup overlapping rules


## Summary of Changes

Unified rule architecture across Format, Lint, and Suggest:

### Phase 1: Folder restructure
- Lifted `Lint/Core/*` → `Core/*` (shared rule framework)
- Lifted `Lint/BuiltInRules/Rules/*` → `Rules/*` (all AST rules)
- Moved `BuiltInRules.swift` → `Rules/AllRules.swift`
- Moved `ExtraRules.swift` → `Rules/Extra.swift`
- Moved `FormatCommand.swift` → `Format/FormatCommand.swift`
- Moved `LintCommand.swift` → `Lint/LintCommand.swift`
- Moved `FormatEngine.swift` → `Format/Engine.swift`
- Moved `FileDiscovery.swift` → top-level

### Phase 2: Extended Core models
- Added `.suggest`, `.concurrency`, `.observation` to `RuleKind`
- Created `Core/Models/Confidence.swift` (from Suggest)
- Added `confidence` and `suggestion` fields to `ReasonedRuleViolation` and `StyleViolation`
- Updated JSON reporter to include new fields when present

### Phase 3: Ported Suggest rules as Lint rules
- 10 single-file rules in `Rules/Suggest/`, `Rules/Concurrency/`, `Rules/Observation/`
- 2 CollectingRule implementations (DeadSymbols, StructuralDuplication)
- All registered in `Rules/AllRules.swift`
- Ported rules are opt-in, lightweight syntax-only versions
- Original Suggest checks kept for deep TypeResolver-enhanced analysis

### Phase 4: CLI + RuleCatalog
- Renamed `Scan` → `Suggest` (alias: `scan`)
- Renamed `ListChecks` → `ListRules` (alias: `list-checks`)
- Created `RuleCatalog.swift` — unified listing across all 3 subsystems
- `list-rules` shows 8 suggest + 262 lint + 138 format = 408 total rules
- JSON output via `--format json`
- Filter by subsystem via `--subsystem suggest|lint|format`
