---
# lv4-z40
title: '`SortImportsRule`: group `@_implementationOnly` imports separately'
status: completed
type: feature
priority: normal
created_at: 2026-04-11T17:53:01Z
updated_at: 2026-04-11T21:44:49Z
sync:
    github:
        issue_number: "182"
        synced_at: "2026-04-11T22:00:30Z"
---

The `SortImportsRule` currently treats all imports as a single alphabetically-sorted group. It should support grouping imports by attribute, placing `@_implementationOnly` imports in a separate group (typically after regular imports).

Upstream reference: swiftlang/swift-format 602.0.0 added separate grouping for `@_implementationOnly` imports in `OrderedImports`.


## Summary of Changes

Added `group_attributed_imports` config option (default `false`) to `SortImportsRule`. When enabled, imports are separated into three groups — regular → `@_implementationOnly` → `@testable` — each independently sorted and separated by blank lines. Approach adapted from swift-format's `OrderedImports` rule.

### Files changed
- `Sources/SwiftiomaticKit/Rules/Ordering/Sorting/SortImportsOptions.swift` — new `group_attributed_imports` option
- `Sources/SwiftiomaticKit/Rules/Ordering/Sorting/SortImportsRule.swift` — `ImportKind` enum, `importKind(of:)` classifier, updated Visitor/Rewriter, new examples
- `Tests/SwiftiomaticTests/Rules/Ordering/OrderingRuleTests.swift` — 6 new tests
- `CLAUDE.md` — new agent rule: always check cited reference implementations first
