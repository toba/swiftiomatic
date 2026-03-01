---
# yqv-1qo
title: Fix all swift-review findings in Configuration/
status: in-progress
type: task
priority: normal
created_at: 2026-03-01T03:17:24Z
updated_at: 2026-03-01T03:23:33Z
sync:
    github:
        issue_number: "113"
        synced_at: "2026-03-01T03:57:23Z"
---

Fix all findings from swift-review analysis of Sources/Swiftiomatic/Configuration/ files.

## Tasks

- [x] Create ConfigValue enum (Sendable wrapper for YAML values)
- [x] Replace lintRuleConfigs [String: Any] with [String: ConfigValue], drop nonisolated(unsafe)
- [x] Update RuleResolver to accept [String: ConfigValue]
- [x] Drop @unchecked Sendable on Configuration
- [x] Eliminate RulesBox, use Mutex<[any Rule]?> directly (Rule is Sendable)
- [x] Cache validRuleIdentifiers as let in init
- [x] Fix invalidRuleIdsWarnedAbout data race with Mutex
- [x] Fix multiline_parameters lint warning
- [x] Replace init(copying:) with self = configuration
- [x] Extract YAML loading helper in loadUnified
- [x] Rename rulesWrapper to ruleSelection
- [x] Replace JSONSerialization with direct SHA-256 in cacheDescription



## Additional Changes

- Removed dead `disabledRuleIdentifiers` lazy var from RuleSelection
- Added `@unchecked Sendable` to RuleSelection (justified: all mutable state is Mutex-protected)
- Made `aliasResolver` closure `@Sendable`
- Added explicit `Sendable` conformance to `RulesMode` and `RuleList`
