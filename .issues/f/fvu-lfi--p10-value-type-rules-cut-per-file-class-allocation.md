---
# fvu-lfi
title: 'P10: Value-type rules — cut per-file class allocations'
status: ready
type: task
priority: normal
created_at: 2026-04-30T15:58:10Z
updated_at: 2026-04-30T15:58:10Z
parent: 6xi-be2
sync:
    github:
        issue_number: "552"
        synced_at: "2026-04-30T16:27:56Z"
---

**Location:** `Sources/SwiftiomaticKit/Syntax/Linter/LintSyntaxRule.swift:6`

Every `LintSyntaxRule` is a class (`class LintSyntaxRule<V>: SyntaxVisitor, ... @unchecked Sendable`). Per file, `ruleCache` lazily builds an instance per visited rule kind. Across thousands of files in a build that's many ARC-traffic + heap-alloc cycles.

## Potential performance benefit

Eliminates one class allocation per (file × enabled-rule) pair. For a 5,000-file build with 80 enabled rules visited that's potentially ~400k class allocations per run, plus the matching deallocs and refcount traffic. Value-type rules could share immutable rule logic and lift any per-file mutable state into `Context` (where it's already partially staged).

## Reason deferred

Large refactor. `SyntaxVisitor` is a class in swift-syntax; rules currently inherit from it directly. Moving to value types means decoupling rules from `SyntaxVisitor`, which interacts with the dispatcher design (P3) and the typed dispatch table (P9). Best done after P9 lands so the dispatcher already drives rules through a function-table indirection.
