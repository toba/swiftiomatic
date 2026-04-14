---
# 5i1-frf
title: 'Phase 2: Extend existing rules'
status: ready
type: task
priority: normal
created_at: 2026-04-14T18:36:37Z
updated_at: 2026-04-14T18:36:37Z
parent: c7r-77o
sync:
    github:
        issue_number: "305"
        synced_at: "2026-04-14T18:45:54Z"
---

Require architectural decisions about modifying existing rules vs standalone.

- [ ] `redundantFileprivate` — Prefer `private` over `fileprivate` where equivalent. Requires extending `FileScopedDeclarationPrivacy` for non-file-scope contexts. Parent: nnl-svw.
- [ ] `redundantParens` — Remove redundant parentheses beyond conditions. Requires extending `NoParensAroundConditions` for return statements, assignments, etc. Parent: nnl-svw.
