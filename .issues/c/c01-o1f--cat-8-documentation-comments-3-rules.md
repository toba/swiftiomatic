---
# c01-o1f
title: 'Cat 8: Documentation & Comments (3 rules)'
status: ready
type: feature
priority: normal
created_at: 2026-04-15T00:27:58Z
updated_at: 2026-04-15T00:27:58Z
parent: qlt-10c
sync:
    github:
        issue_number: "317"
        synced_at: "2026-04-15T00:34:46Z"
---

| SwiftLint Rule | Swiftiomatic Name | Scope | Description |
|---|---|---|---|
| `orphaned_doc_comment` | OrphanedDocComment | `.lint` | `///` comment not attached to any declaration |
| `local_doc_comment` | NoLocalDocComments | `.lint` | `///` inside function bodies should be `//` |
| `expiring_todo` | ExpiringTodo | `.lint` | TODO/FIXME with dates should be resolved by that date |
