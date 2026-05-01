---
# 4dx-qkx
title: noDataDropPrefixInLoop has high false-positive rate on String/non-Data values
status: ready
type: bug
priority: normal
created_at: 2026-05-01T00:30:40Z
updated_at: 2026-05-01T00:30:40Z
sync:
    github:
        issue_number: "594"
        synced_at: "2026-05-01T00:49:16Z"
---

Discovered while running c12-swt dogfood: `noDataDropPrefixInLoop` flagged 36 sites in `Sources/`, most of which are `String.prefix(1)`, `String.dropFirst()`, etc. on values unrelated to the iterated collection.

Examples:

```
Sources/SwiftiomaticKit/Configuration/ConfigurationRegistry.swift:16:30: warning: [noDataDropPrefixInLoop] '.prefix' inside a loop copies the collection on every iteration
Sources/SwiftiomaticKit/Configuration/ConfigurationRegistry.swift:16:64: warning: [noDataDropPrefixInLoop] '.dropFirst' inside a loop copies the collection on every iteration
```

The actual line: `let derivedKey = typeName.prefix(1).lowercased() + typeName.dropFirst()` — these are short String operations on a `typeName` local variable, not a quadratic copy of the iterated collection.

The rule should at minimum:
1. Restrict to `Data` (its name suggests so), OR
2. Only fire when the receiver of `.dropFirst`/`.prefix` is the same identifier as the loop's iterated collection or a value derived from it inside the loop body

Currently the rule has been disabled for this project.
