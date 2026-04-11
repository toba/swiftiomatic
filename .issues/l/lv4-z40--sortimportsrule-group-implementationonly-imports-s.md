---
# lv4-z40
title: '`SortImportsRule`: group `@_implementationOnly` imports separately'
status: ready
type: feature
priority: normal
created_at: 2026-04-11T17:53:01Z
updated_at: 2026-04-11T17:53:01Z
sync:
    github:
        issue_number: "182"
        synced_at: "2026-04-11T18:44:01Z"
---

The `SortImportsRule` currently treats all imports as a single alphabetically-sorted group. It should support grouping imports by attribute, placing `@_implementationOnly` imports in a separate group (typically after regular imports).

Upstream reference: swiftlang/swift-format 602.0.0 added separate grouping for `@_implementationOnly` imports in `OrderedImports`.
