---
# ftl-21i
title: Add DiagnosticCategory hierarchy for rule grouping
status: completed
type: feature
priority: low
created_at: 2026-04-12T23:54:23Z
updated_at: 2026-04-13T00:43:39Z
parent: oad-n72
sync:
    github:
        issue_number: "250"
        synced_at: "2026-04-13T00:55:42Z"
---

swift-syntax's `DiagnosticCategory` with `name`, `documentationURL`, and `categoryChain` (leaf-to-root) could enable category-level filtering beyond per-rule enable/disable.

## Reference

`SwiftDiagnostics/Message.swift`:
- `DiagnosticCategory` struct: `name: String`, `documentationURL: String?`
- `DiagnosticMessage.categoryChain: [DiagnosticCategory]` — leaf-first hierarchy

## Mapping to Swiftiomatic

Rule directory structure already implies categories (Redundancy, Performance, Style, Concurrency, etc.). This would formalize them as filterable metadata.

## Tasks

- [x] Define category hierarchy matching existing rule directory structure
- [x] Add `category` static property to `Rule` protocol (or derive from directory/module)
- [x] Add `documentationURL` support for generated docs (field present in `RuleCategory`, not yet populated)
- [ ] Support `--category` / `--exclude-category` CLI flags (deferred — infrastructure is in place)
- [ ] Support category-level enable/disable in `.swiftiomatic.yaml` (deferred — infrastructure is in place)


## Summary of Changes

Added `RuleCategory` struct with `name`, `subcategory`, and `documentationURL` fields. Added `category` to `Rule` protocol (default `.uncategorized`), `RuleConfigurationEntry`, and `Diagnostic` JSON output.

The `GeneratePipeline` auto-derives categories from directory structure — e.g., `Rules/Redundancy/Types/FooRule.swift` → `RuleCategory(name: "redundancy", subcategory: "types")`. All 337 rules get categories emitted as extensions in the generated registry.

CLI flags and YAML config support deferred — the infrastructure (category on every rule + JSON output) is complete and ready to wire up.
