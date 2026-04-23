---
# evy-hii
title: Fix ruleNameCache to use custom static name
status: completed
type: bug
priority: normal
created_at: 2026-04-18T04:27:59Z
updated_at: 2026-04-18T04:30:46Z
sync:
    github:
        issue_number: "333"
        synced_at: "2026-04-23T05:30:24Z"
---

RuleNameCacheGenerator always uses the class name (typeName) as the cache value, ignoring custom `static let name` overrides on rules. Rules like ASCIIIdentifiers (name: identifiersMayOnlyUseASCII), DocComments (name: convertRegularCommentToDocC), etc. show incorrectly.

- [x] Add `customName` to DetectedRule in RuleCollector
- [x] Extract `static let name` from AST in RuleCollector
- [x] Use customName in RuleNameCacheGenerator
- [x] Regenerate


## Summary of Changes

- Added `customName` field to `DetectedRule` and `ruleName` computed property (returns custom name or falls back to type name)
- Added `extractCustomName(from:)` to parse `static let name = "..."` from rule AST
- Updated all generators (RuleNameCache, RuleRegistry, ConfigSchema, RuleDocumentation) to use `ruleName` instead of `typeName` for config keys and display names
- Regenerated all `*+Generated.swift` files
