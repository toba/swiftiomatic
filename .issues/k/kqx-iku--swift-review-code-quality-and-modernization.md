---
# kqx-iku
title: 'Swift review: code quality and modernization'
status: completed
type: epic
priority: normal
created_at: 2026-04-14T02:41:09Z
updated_at: 2026-04-14T03:06:24Z
sync:
    github:
        issue_number: "267"
        synced_at: "2026-04-14T03:07:03Z"
---

Comprehensive agentic Swift review of the Swiftiomatic codebase. Covers typed throws, XCTest migration, performance anti-patterns, concurrency modernization, code duplication, and naming conventions.

## Scope
- Sources/ (124 Swift files)
- Tests/ (124 Swift files)
- Plugins/ (2 Swift files)

## Categories
1. Typed throws (Swift 6)
2. XCTest → Swift Testing migration
3. Performance anti-patterns
4. Concurrency modernization (@unchecked Sendable, DispatchQueue → Mutex)
5. Code duplication / consolidation
6. Naming conventions
7. Code quality (debug prints, fatalError patterns, TODOs)


## Summary of Findings

### High priority (3 issues)
1. **`olt-gzj` Add typed throws** — 12+ functions throw single error types but declare untyped `throws`
2. **`rwb-wt3` XCTest → Swift Testing** — 124 test files, 0% migrated, phased plan ready
3. **`w98-vai` O(n²) performance** — 2 quadratic insert patterns (RuleMask, GroupNumericLiterals)

### Normal priority (2 issues)
4. **`g2k-uar` Concurrency modernization** — 4 `@unchecked Sendable`, 1 DispatchQueue → Mutex, 1 nonisolated(unsafe) metatype
5. **`f72-osd` Consolidate rule duplication** — 3 doc rules with shared extraction, multi-decl visitor boilerplate

### Low priority (2 issues)
6. **`fg4-zkc` Naming conventions** — 3 protocols with `-Protocol` suffix, boolean naming in OrderedImports
7. **`ft5-6do` Code quality cleanup** — debug prints, assert(false), fatalError override pattern, stale TODOs

### Not applicable (skipped)
- CKSyncEngine — not used
- SwiftUI patterns — CLI tool, no UI
- NotificationCenter — not used
- NSAttributedString — not used
- Subprocess teardown — no subprocess usage in main code
- `@_cdecl`/`@_specialize` — not used
- `Result<>` return types — not used
- `withObservationTracking` — not used
- `weak var` → `weak let` — no weak refs found
- `.onAppear` + Task — no SwiftUI
- Collection type selection (6a) — no significant opportunities found
