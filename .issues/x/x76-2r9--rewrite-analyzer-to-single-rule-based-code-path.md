---
# x76-2r9
title: Rewrite Analyzer to single Rule-based code path
status: ready
type: task
priority: normal
created_at: 2026-02-28T17:05:56Z
updated_at: 2026-02-28T17:06:02Z
parent: dz8-axs
blocked_by:
    - b7i-7ys
    - 5w8-efc
    - bgn-y3w
---

After all Checks are merged into Rules, collapse the Analyzer's dual code paths into one.

## Current state
- `runSuggestChecks()` — walks trees with Check instances, produces `[Finding]`
- `runLintRules()` — validates with Rule instances, produces `[StyleViolation]` → `[Diagnostic]`

## Target state
Single path:
1. Parse files → build SwiftLintFile instances
2. Collect phase: `collectInfo()` for CollectingRule instances
3. Validate phase: `validate()` for all rules
4. Async enrichment: `enrichAsync()` for AsyncEnrichableRule rules
5. Merge violations → Diagnostic → output

## Steps

- [ ] Remove `makeChecks()` method
- [ ] Remove `runSuggestChecks()` method
- [ ] Add async enrichment loop after validation
- [ ] Update `--suggest-only` / `--lint-only` flags to filter by rule identifier or RuleDescription.kind
- [ ] Update output formatters to accept `[Diagnostic]` instead of `[Finding]`
- [ ] Delete Check protocol, BaseCheck class, Finding struct
- [ ] Build and test

## Key files
- `Sources/Swiftiomatic/Suggest/Analyzer.swift` — main rewrite target
- `Sources/Swiftiomatic/Suggest/Output/` — formatters
- `Sources/Swiftiomatic/RuleCatalog.swift` — remove suggest-specific section
- `Sources/Swiftiomatic/swiftiomatic.swift` — CLI command wiring
