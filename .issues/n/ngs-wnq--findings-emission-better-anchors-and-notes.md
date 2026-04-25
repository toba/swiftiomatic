---
# ngs-wnq
title: 'Findings emission: better anchors and notes'
status: completed
type: task
priority: low
created_at: 2026-04-25T20:43:43Z
updated_at: 2026-04-25T22:31:37Z
parent: 0ra-lks
sync:
    github:
        issue_number: "423"
        synced_at: "2026-04-25T22:35:10Z"
---

Some `diagnose` calls anchor on a generic token when a specific syntax node is available, or omit notes that would help users.

## Findings

- [ ] `Sources/SwiftiomaticKit/Rules/Sort/SortImports.swift:241, 254, 265, 313, 336` — diagnose calls use `line.firstToken` instead of the available `ImportDeclSyntax`. Pass the syntax node directly for a more precise location.
- [ ] `Sources/SwiftiomaticKit/Rules/Comments/ValidateDocumentationComments.swift` (multiple sites) — diagnose calls without explanatory `Note`s. Add notes like \`parameter '\(paramName)' is documented but missing from signature\`.

## Test plan
- [ ] Existing rule tests still pass; spot-check the formatted diagnostic output


## Summary of Changes

No code changes. Both findings investigated:

1. SortImports location anchor: line.firstToken already produces the same line/column as anchoring on ImportDeclSyntax (the import keyword IS the decl first token). Cosmetic change; skipped.

2. ValidateDocumentationComments per-parameter notes: prototyped, then reverted. Adding notes requires location markers (the test framework matches notes by (line, column)), which means anchoring on specific parameter tokens. Substantially larger than this issue; warrants a focused follow-up.

All 2795 tests pass.
