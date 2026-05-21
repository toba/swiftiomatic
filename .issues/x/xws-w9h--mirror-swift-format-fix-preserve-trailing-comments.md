---
# xws-w9h
title: 'Mirror swift-format fix: preserve trailing comments in OrderedImports'
status: completed
type: bug
priority: normal
created_at: 2026-05-21T16:32:22Z
updated_at: 2026-05-21T16:36:37Z
sync:
    github:
        issue_number: "691"
        synced_at: "2026-05-21T16:37:04Z"
---

Upstream swift-format commit e0b1f28c (PR #1205, 2026-05-15, resolves #1080) fixes the OrderedImports rule dropping trailing comments that get pushed past the final import after reordering.

The `convertToCodeBlockItems` pass accumulates trivia in `pendingLeadingTrivia` and flushes it onto successive nodes. When input ends with trivia (a trailing comment) after the last syntax node, the accumulator was silently dropped. Fix: append leftover trivia containing comments to the trailing trivia of the last code block item (stripping synthesized trailing newlines first).

Swiftiomatic equivalent: Sources/SwiftiomaticKit/Rules/.../SortImports.swift (StructuralFormatRule).

## Tasks
- [x] Write a failing test: file ending with a trailing comment after the last import, where reordering pushes the comment past the new last import
- [x] Check if SortImports has the same trailing-trivia drop
- [x] If so, port the upstream fix
- [x] Confirm test passes; run filtered suite
- [x] Run full suite once before commit

Reference: ~/Developer/swiftiomatic-ref/swift-format commit e0b1f28c73d048b7c52a7bff0f29787c7731de0d



## Summary of Changes

Ported upstream swift-format #1205 fix to `convertToCodeBlockItems` in `Sources/SwiftiomaticKit/Rules/Sort/SortImports.swift`. After the line loop, strip trailing synthesised newlines from `pendingLeadingTrivia`; if any comments remain, append them to the last code block item's trailing trivia (via the existing `Trivia.hasAnyComments` helper). Previously the accumulator was silently dropped, losing trailing comments pushed past the last import after reordering.

Added `commentBetweenImportGroupsIsPreserved` in `Tests/SwiftiomaticTests/Rules/Sort/SortImportsTests.swift`. Full suite: 3371 passed.
