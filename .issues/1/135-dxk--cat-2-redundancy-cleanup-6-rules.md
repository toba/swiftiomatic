---
# 135-dxk
title: 'Cat 2: Redundancy & Cleanup (6 rules)'
status: ready
type: feature
priority: normal
created_at: 2026-04-15T00:27:58Z
updated_at: 2026-04-15T00:27:58Z
parent: qlt-10c
sync:
    github:
        issue_number: "319"
        synced_at: "2026-04-15T00:34:46Z"
---

Remove dead code and unnecessary constructs. Auto-fixable ones → `SyntaxFormatRule`.

| SwiftLint Rule | Swiftiomatic Name | Scope | Description |
|---|---|---|---|
| `redundant_nil_coalescing` | RedundantNilCoalescing | `.format` | `x ?? nil` is redundant |
| `unneeded_override` | RedundantOverride | `.lint` | Override that just calls super with identical args |
| `unused_enumerated` | RedundantEnumerated | `.format` | `.enumerated()` when index or item is unused |
| `unneeded_parentheses_in_closure_argument` | NoParensInClosureParams | `.format` | `{ (x, y) in }` → `{ x, y in }` |
| `redundant_set_access_control` | RedundantSetterACL | `.lint` | Setter ACL same as property ACL is redundant |
| `unneeded_escaping` | RedundantEscaping | `.format` | `@escaping` when closure doesn't actually escape (complex — needs escape analysis) |
