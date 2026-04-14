---
# b0l-cxg
title: Deferred blocked rules
status: draft
type: task
priority: normal
created_at: 2026-04-14T18:37:52Z
updated_at: 2026-04-14T18:37:52Z
parent: c7r-77o
sync:
    github:
        issue_number: "299"
        synced_at: "2026-04-14T18:45:53Z"
---

Rules deferred due to complexity or limited value.

- [ ] `leadingDelimiters` — Move leading `.`/`,` to end of previous line. Multi-token trivia manipulation; trivial in flat token stream, complex in syntax tree. Parent: j0v-ttz.
- [ ] `redundantLet` — Remove `let` from `let _ = expr`. Ties `let` to binding specifier.
- [ ] `redundantStaticSelf` — Remove `Self.` prefix in static context. Node type change (`MemberAccessExprSyntax` → `DeclReferenceExprSyntax`).
- [ ] `redundantType` — Remove redundant type annotation. Already a format rule; listed here for additional coverage (array/generic/closure patterns tracked in pfo-ol9).
