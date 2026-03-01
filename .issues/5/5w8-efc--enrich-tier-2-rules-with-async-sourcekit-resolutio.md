---
# 5w8-efc
title: Enrich Tier 2 rules with async SourceKit resolution
status: completed
type: task
priority: normal
created_at: 2026-02-28T17:05:21Z
updated_at: 2026-02-28T17:25:11Z
parent: dz8-axs
blocked_by:
    - qjw-hor
sync:
    github:
        issue_number: "89"
        synced_at: "2026-03-01T01:01:47Z"
---

Four Checks add SourceKit type resolution that their paired Rule lacks. Port the async enrichment logic into the Rule as `AsyncEnrichableRule` conformance, then delete the Check.

## Rules to enrich

- [ ] `TypedThrowsRule` — resolve __unknown__ throw types via SourceKit (from TypedThrowsCheck.resolveTypeQueries)
- [ ] `AnyEliminationRule` — resolve type aliases to Any (from AnyEliminationCheck)
- [ ] `ConcurrencyModernizationRule` — upgrade DispatchQueue confidence via type resolution (from ConcurrencyModernizationCheck)
- [ ] `NamingHeuristicsRule` — find inferred-Bool bindings via expressionTypes (from NamingHeuristicsCheck)

## For each rule

1. Add `AsyncEnrichableRule` conformance
2. Port the async resolution logic from the Check's `resolveTypeQueries()`
3. Delete the Check file
4. Update Analyzer.makeChecks() to remove the Check instantiation
5. Verify tests pass

## Delete these files when done

- `Rules/Suggest/TypedThrowsCheck.swift`
- `Rules/Suggest/AnyEliminationCheck.swift`
- `Rules/Suggest/ConcurrencyModernizationCheck.swift`
- `Rules/Suggest/NamingHeuristicsCheck.swift`

## Key files
- Each `*Check.swift` — source of async resolution logic
- Each `*Rule.swift` — target for AsyncEnrichableRule conformance
- `Sources/Swiftiomatic/Suggest/Analyzer.swift` — makeChecks() method
