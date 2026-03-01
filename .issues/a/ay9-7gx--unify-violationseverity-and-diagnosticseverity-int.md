---
# ay9-7gx
title: Unify ViolationSeverity and DiagnosticSeverity into one enum
status: ready
type: task
priority: normal
created_at: 2026-03-01T07:58:51Z
updated_at: 2026-03-01T07:58:51Z
sync:
    github:
        issue_number: "122"
        synced_at: "2026-03-01T08:00:21Z"
---

These two severity enums serve overlapping purposes but are deeply entangled throughout the codebase. Unifying them requires careful migration of all call sites.

Deferred from vu5-l8x because of the scope of changes required.
