---
# 56o-cnx
title: 'Remaining medium gaps: EmptyBraces linebreak, RedundantType if/switch + Set literal'
status: completed
type: task
priority: high
created_at: 2026-04-12T23:26:24Z
updated_at: 2026-04-12T23:43:22Z
parent: a9u-qgt
sync:
    github:
        issue_number: "247"
        synced_at: "2026-04-13T00:25:21Z"
---

Remaining unchecked items from audit epic a9u-qgt.

## Tasks

- [x] EmptyBraces: add `linebreak` style mode (brace on new line with indentation)
- [x] RedundantType: if/switch expression branch type comparison (SE-0380)
- [x] RedundantType: Set with inferred array literal element type (`Set<Int> = [1, 2, 3]` → `Set = [1, 2, 3]`)


## Summary of Changes

- EmptyBracesRule: added `linebreak` style option — puts closing brace on new line with matching indentation
- RedundantTypeAnnotationRule: detects redundant type annotations on if/switch expressions (SE-0380) where all branches construct the same type
- RedundantTypeAnnotationRule: detects redundant generic argument on `Set<T>` when element type is inferable from array literal
