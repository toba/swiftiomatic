---
# slg-5gh
title: SimplifyGenericConstraints diagnostics anchor to wrong source line
status: completed
type: bug
priority: normal
created_at: 2026-05-01T21:58:31Z
updated_at: 2026-05-01T22:14:40Z
sync:
    github:
        issue_number: "615"
        synced_at: "2026-05-01T23:12:04Z"
---

The rule's `transform` extracts the where-clause `conformance` node from `visited` (the rewritten subtree) and calls `Self.diagnose(on: conformance, ...)`. The static `emitFinding` helper resolves the source location via `node.startLocation(converter: context.sourceLocationConverter)` — but the converter is built from the original source while `conformance`'s absolute byte offset reflects its position inside the detached rewritten subtree. Result: when a triggering decl is preceded by other source content, the finding lands on whatever original-source line shares that byte offset (typealiases, doc comments, URLs above the decl).

## Reproduction

A file like:

```
typealias MoveRowHandler = (IndexSet, Int) -> Void

/// doc
/// comment
struct OutlineList<Data, RowContent>: View where Data: RecursiveCollection, RowContent: View { ... }
```

…produces `simplifyGenericConstraints` warnings on the typealias and doc-comment lines instead of on the `where` clause.

## Tasks

- [x] Add a failing test that places the triggering struct after preceding content and asserts the finding line/column lands on the original `where` clause
- [x] Fix `SimplifyGenericConstraints.simplifyConstraints` to diagnose against the original (not the rewritten) node
- [x] Re-run the SimplifyGenericConstraints test suite



## Summary of Changes

`Sources/SwiftiomaticKit/Rules/Generics/SimplifyGenericConstraints.swift`: thread the `original` decl through `simplifyConstraints`, look up the matching `GenericRequirementSyntax` in the original where clause by the same enumeration index, and pass that attached node as the diagnose anchor. `original` carries correct positions because it is the node passed to the parent rewriter's `visit(_:)` while the tree is still attached, whereas `visited` (the result of `super.visit(node)`) is a detached subtree whose `position` is offset relative to its own root.

Verified end-to-end against `OutlineList.swift` (the user's repro). Before: warnings landed on lines 4, 6, 22. After: warnings land on lines 23 and 79, correctly anchored to each `where` clause. Full test suite passes (3161 tests).
