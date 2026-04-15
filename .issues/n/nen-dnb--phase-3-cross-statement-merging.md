---
# nen-dnb
title: 'Phase 3: Cross-statement merging'
status: completed
type: task
priority: normal
created_at: 2026-04-14T18:36:45Z
updated_at: 2026-04-14T20:12:04Z
parent: c7r-77o
sync:
    github:
        issue_number: "304"
        synced_at: "2026-04-15T00:34:46Z"
---

Pattern exists in `UseEarlyExits` (windowed iteration over `CodeBlockItemListSyntax`).

- [x] `conditionalAssignment` — Use if/switch expressions for assignment. Merge `let x; if c { x = a } else { x = b }` → `let x = if c { a } else { b }`. Cross-statement restructuring.
- [x] `redundantProperty` — Remove property assigned and immediately returned. Merge `let result = x; return result` → `return x`.
- [x] `redundantClosure` — Remove immediately-invoked closures. Unwrap `{ return x }()` → `x`.
- [x] `redundantEquatable` — Remove hand-written `Equatable`. Coordinated removal from inheritance clause AND `==` function from member block.


## Summary of Changes

Implemented all 4 cross-statement merging rules as format rules with auto-fix:

1. **ConditionalAssignment** (opt-in) — merges `let x: Type` + exhaustive `if/switch` with branch assignments into `let x: Type = if/switch { value }`. Handles nested if/switch recursively.
2. **RedundantProperty** — merges `let x = expr; return x` into `return expr`. Converted from lint-only to format rule.
3. **RedundantClosure** — unwraps `{ expr }()` and `{ return expr }()` into `expr`. Converted from lint-only to format rule. Skips closures with parameters, fatalError, throw, try/await.
4. **RedundantEquatable** (opt-in) — removes hand-written `static func ==` from structs when it compares exactly the stored instance properties. Converted from lint-only to format rule. Handles Hashable, didSet properties, computed/static property exclusion, attributed functions.

All tests adapted from SwiftFormat reference tests (79 assertions total).
