---
# nen-dnb
title: 'Phase 3: Cross-statement merging'
status: ready
type: task
priority: normal
created_at: 2026-04-14T18:36:45Z
updated_at: 2026-04-14T18:36:45Z
parent: c7r-77o
sync:
    github:
        issue_number: "304"
        synced_at: "2026-04-14T18:45:53Z"
---

Pattern exists in `UseEarlyExits` (windowed iteration over `CodeBlockItemListSyntax`).

- [ ] `conditionalAssignment` — Use if/switch expressions for assignment. Merge `let x; if c { x = a } else { x = b }` → `let x = if c { a } else { b }`. Cross-statement restructuring.
- [ ] `redundantProperty` — Remove property assigned and immediately returned. Merge `let result = x; return result` → `return x`.
- [ ] `redundantClosure` — Remove immediately-invoked closures. Unwrap `{ return x }()` → `x`.
- [ ] `redundantEquatable` — Remove hand-written `Equatable`. Coordinated removal from inheritance clause AND `==` function from member block.
