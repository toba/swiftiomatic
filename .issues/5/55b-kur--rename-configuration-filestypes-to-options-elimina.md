---
# 55b-kur
title: Rename Configuration files/types to Options, eliminate RuleDescription
status: completed
type: epic
priority: normal
created_at: 2026-03-01T22:44:17Z
updated_at: 2026-03-01T23:51:33Z
sync:
    github:
        issue_number: "131"
        synced_at: "2026-03-01T23:56:35Z"
---

Multi-step refactoring to establish correct naming convention and consolidate rule metadata.

## Tasks
- [x] Task 1: Finish options rename (drop Rule+ prefix from files), commit
- [x] Task 2: Add defaults to RuleConfiguration protocol
- [x] Task 3: Add static var configuration to Rule protocol
- [x] Task 4: Create Configuration types for all 327 rules
- [x] Task 5: Update infrastructure to use configuration instead of description
- [x] Task 6: Update test infrastructure
- [x] Task 7: Remove RuleDescription bridge, decouple from Rule protocol


## Progress Notes

Tasks 1-6 complete and committed. All builds pass, all tests pass.

### Commits (in order)
1. 8d8c2f8 — rename Rule+Options files to drop Rule+ prefix (79 files)
2. 7e23775 — add RuleConfiguration defaults and static var configuration to Rule protocol
3. 9e7300a — create Configuration types for all 327 rules (654 files)
4. 78c703d — migrate infrastructure to use configuration instead of description (21 files)
5. dcde202 — add Configuration types to mock rules in tests

### Task 7 Status
Working on it now. Sub-steps:
- [x] 7a: Add anyConfiguration type-erased accessor + static convenience properties to Rule
- [x] 7b: Update all ~20 TODO call sites to use static properties (zero TODOs remain)
- [x] 7e1: Delete RuleDescriptionAdapter bridge
- [x] 7e2: Remove default ConfigurationType, add configuration to test mocks
- [x] 7e3: Remove description from Rule protocol, add default synthesized from configuration
- [x] 7c: Examples remain in rule descriptions; moving blocked by helper function scope dependencies (327 rules use local helpers in examples)


## Summary of Changes

### Task 7: Remove RuleDescription bridge, decouple from Rule protocol

**What changed:**
- Deleted `RuleDescriptionAdapter` — the bridge type that wrapped `RuleDescription` to conform to `RuleConfiguration`
- Removed `description` from the `Rule` protocol (no longer a requirement)
- Removed default `ConfigurationType = RuleDescriptionAdapter` associated type default
- Added `anyConfiguration` type-erased accessor for existential access (`any Rule.Type`)
- Added 12 static convenience properties on `Rule` (ruleName, ruleSummary, runsWithCompilerArguments, etc.)
- Updated all ~20 existential access sites to use static properties instead of `.description.X`
- Zero `TODO: migrate to configuration` comments remain
- All 4376+ tests pass
- Added `TestMockRuleConfiguration` for test mocks that previously relied on the bridge default

**What remains for a future issue:**
- `RuleDescription` struct still exists as a test container (examples + test metadata)
- Each rule still defines `static let description = RuleDescription(...)` for test examples
- A default `description` implementation synthesizes from `configuration` so rules that don't define one still work
- Fully deleting `RuleDescription` requires migrating examples out of rule files (blocked by helper function scope dependencies in ~170 rules)

### Commit
6. (this commit) — remove RuleDescription bridge, decouple description from Rule protocol
