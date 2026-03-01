---
# 7y2-kma
title: Unify rule metadata and align rule protocols
status: completed
type: task
priority: normal
created_at: 2026-03-01T20:20:03Z
updated_at: 2026-03-01T21:55:44Z
sync:
    github:
        issue_number: "128"
        synced_at: "2026-03-01T21:56:04Z"
---

Unify rule metadata into a single RuleConfiguration protocol, rename the existing YAML-parsing protocol to RuleOptions, and fold three marker protocols into data fields.

## Implementation Checklist

- [x] Phase 1: Rename RuleConfiguration → RuleOptions (~107 files, mechanical find-and-replace)
- [x] Phase 2: Fold marker protocols into RuleDescription (add isOptIn/requiresSourceKit/requiresCompilerArguments fields, update ~165 rules, update all consumers)
- [x] Phase 3: Create unified RuleConfiguration protocol and supporting types (RuleExamples, ConfigOptionDescriptor, RuleConfigurationEntry, LintRuleConfigurationAdapter, FormatRuleConfigurationAdapter)
- [ ] Phase 4: Wire up consumers (RuleCatalog, SwiftiomaticLib, CLI, AppModel, remove RuleCatalogEntry)

## Phase 4 Status — IN PROGRESS

Completed so far in Phase 4:
- [x] RuleCatalog rewritten to use adapters, returns `[RuleConfigurationEntry]` via `allEntries()`
- [x] SwiftiomaticLib.ruleCatalog() delegates to RuleCatalog.allEntries()
- [x] CLI (SwiftiomaticCLI list-rules) updated to use new API
- [x] Xcode app files updated: RuleCatalogEntry → RuleConfigurationEntry, .identifier → .id, .description → .summary
- [x] Old RuleCatalogEntry.swift deleted
- [x] SPM build succeeds (swift build --build-tests)
- [x] SPM tests pass (4387 passed)

Remaining for Phase 4:
- [x] Build Xcode app target (SwiftiomaticApp) — fixed RulesTab.swift (.identifier→.id, .description→.summary) and FormatRuleConfigurationAdapter (duplicate propertyName crash)
- [x] Run full test suite — 4386 tests pass
- [x] Verify `swiftiomatic list-rules --format json` output includes full metadata

## Key Files Changed

### Phase 1 (rename)
- `Rules/RuleConfiguration.swift` → `Rules/RuleOptions.swift` (protocol rename)
- `Models/RuleConfigurationDescription.swift` → `Models/RuleOptionsDescription.swift`
- ~107 files: sed rename of types (RuleConfiguration→RuleOptions, ConfigurationType→OptionsType, etc.)

### Phase 2 (marker protocols)
- `Models/RuleDescription.swift`: Added `isOptIn`, `requiresSourceKit`, `requiresCompilerArguments` fields with defaults
- ~165 rule files: Added `isOptIn: true` to OptInRule conformers, removed explicit `: OptInRule` conformance
- 5 analyzer rules: Added `isOptIn: true, requiresSourceKit: true, requiresCompilerArguments: true`
- 4 SourceKit-requiring rules: Added `requiresSourceKit: true`
- `Rules/Rule.swift`: Deprecated OptInRule/SyntaxOnlyRule/AnalyzerRule (kept for behavioral defaults), updated requiresSourceKit computed property
- Consumer updates: RuleResolver, RuleCatalog, RuleDocumentation, PublicAPI, Configuration+Parsing, Configuration+RulesMode, Configuration+RuleSelection, Linter, Request+SafeSend, LintTestHelpers
- Test fix: CollectingRuleTests — added description override for AnalyzerRule mock specs

### Phase 3 (new types)
- `Rules/RuleConfiguration.swift` (NEW): Unified protocol with 16 metadata properties
- `Models/RuleExamples.swift` (NEW): CodeExample, CorrectionExample, RuleExamples
- `Models/ConfigOptionDescriptor.swift` (NEW): ConfigValueType, ConfigOptionDescriptor
- `Models/RuleConfigurationEntry.swift` (NEW): Concrete Codable struct
- `Rules/LintRuleConfigurationAdapter.swift` (NEW): Wraps Rule.Type → RuleConfiguration
- `Rules/FormatRuleConfigurationAdapter.swift` (NEW): Wraps FormatRule → RuleConfiguration

### Phase 4 (consumer wiring)
- `Rules/RuleCatalog.swift`: Rewritten with allEntries()/entry(id:)/entries(for:)
- `PublicAPI.swift`: Simplified to delegate to RuleCatalog
- `SwiftiomaticCLI.swift`: Updated list-rules to use new API
- `Xcode/SwiftiomaticApp/`: All 4 files migrated from RuleCatalogEntry to RuleConfigurationEntry
- `Models/RuleCatalogEntry.swift`: DELETED


## Summary of Changes

Completed Phase 4 consumer wiring. Fixed two remaining issues:
1. **RulesTab.swift** — updated stale property references (`.identifier`→`.id`, `.description`→`.summary`) to match `RuleConfigurationEntry`
2. **FormatRuleConfigurationAdapter** — fixed fatal crash from duplicate `propertyName` keys in `Descriptors.all` (deprecated/renamed options share the same keyPath). Changed `uniqueKeysWithValues` to `uniquingKeysWith` to keep the first (current) descriptor.

All targets build (SPM + Xcode app), all 4386 tests pass, CLI JSON output includes full rule metadata.
