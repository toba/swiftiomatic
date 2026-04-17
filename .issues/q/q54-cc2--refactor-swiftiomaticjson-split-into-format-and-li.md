---
# q54-cc2
title: 'Refactor swiftiomatic.json: split into format and lint sections'
status: completed
type: feature
priority: normal
created_at: 2026-04-17T22:56:48Z
updated_at: 2026-04-17T23:13:39Z
---

- [x] Update RuleRegistryGenerator to produce formatRules/lintRules sets
- [x] Rewrite Configuration.swift Codable layer (version 3, format/lint sections)
- [x] Update Configuration+Dump.swift asJsonString()
- [x] Update ConfigurationSchemaGenerator for v3 structure
- [x] Update ConfigurationTests for v3 JSON
- [x] Restructure swiftiomatic.json to v3
- [x] Regenerate and verify build + tests


## Summary of Changes

Refactored swiftiomatic.json from flat v2 format to v3 with `format` and `lint` sections. Format section contains formatting settings + format rules (SyntaxFormatRule). Lint section contains lint rules (SyntaxLintRule). Internal Configuration struct stays flat — only the Codable boundary changed. All 2346 tests pass.
