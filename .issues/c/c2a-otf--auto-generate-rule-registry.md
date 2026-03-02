---
# c2a-otf
title: Auto-generate rule registry
status: completed
type: task
priority: normal
created_at: 2026-03-02T21:40:56Z
updated_at: 2026-03-02T22:22:26Z
parent: a2a-2wk
blocked_by:
    - llb-uss
sync:
    github:
        issue_number: "137"
        synced_at: "2026-03-02T23:47:36Z"
---

Replace the manual 323-entry `allRules` array in `RuleRegistry+AllRules.swift` with auto-generated code.

## Current State
- `RuleRegistry+AllRules.swift` has ~323 explicit `.self` entries
- Forgetting to add a new rule means it silently never runs
- No compile-time or CI check catches missing registrations

## Target State
- A generator (can share infrastructure with the dispatch pipeline generator) scans for types conforming to `Rule` and produces the registry
- Or: use the dispatch pipeline generator's rule discovery to also emit the registry
- CI step verifies generated code matches source

## Tasks
- [x] Extend the rule file scanner (from dispatch pipeline task) to collect all Rule-conforming types
- [x] Generate `RuleRegistry+AllRules.swift` with discovered rules
- [x] Add CI verification that generated file matches source rules
- [x] Delete manual `allRules` array


## Summary of Changes

Extended `RuleCollector` to return `RuleTypeInfo` for all structs with `static let id` (not just SwiftSyntax rules). Created `RegistryEmitter` to generate the registry file. Updated `GeneratePipeline.main()` to emit both the pipeline and registry. Deleted the manual 323-entry file. The generator found 327 rules — 4 were missing from the manual list (RedundantGetRule, RedundantParensRule, RedundantPublicRule, RedundantStaticSelfRule). All 3998 tests pass.
