---
# dnd-wao
title: Port upstream swift-format fixes (rule bugfixes + SwiftTestingNamingConventions)
status: completed
type: task
priority: normal
created_at: 2026-07-02T19:30:26Z
updated_at: 2026-07-02T19:41:16Z
sync:
    github:
        issue_number: "746"
        synced_at: "2026-07-02T19:43:27Z"
---

Follow-up from /cite review on 2026-07-02. Four upstream swiftlang/swift-format `main` commits are candidates for porting into Swiftiomatic.

## Checklist

- [x] **NoAssignmentInExpressions false positive with custom operators** (upstream #1232, `74de7f0`) — walk up past enclosing infix operators whose operator is absent from the operator table (mirroring the existing try/await/unsafe walk), so `x = try f() ?! error` is not mis-folded as an embedded assignment. Also switch the rule's test harness to error-swallowing `foldAll(_:errorHandler:)` so custom operators can be exercised.
- [x] **OneCasePerLine: allow intentional line breaks after `case`** (upstream #1221, `b42c1de`) — ported into Swiftiomatic's `SplitMultipleDeclsPerLine` (the local equivalent). Skip cases whose elements have no associated values so their continuation-line trivia isn't disturbed (`case\n  first` was collapsing to `casefirst`). Raw values already permitted to share a `case` here, so only associated values force a split.
- [x] **OrderedImports: ignore backticks when sorting imports** (upstream #1233, `34353c5`) — ported into `SortImports`: added backtick-normalized `sortComponents`/`sortName` on `Line`, used for both alphabetical (component-wise) and length sort orders.
- [x] **Evaluate adopting SwiftTestingNamingConventions rule** (upstream #1236, `d8da499`) — evaluated; it's a net-new opinionated rule, not a bugfix. **Deferred to its own issue `iqr-ybv`** so this issue can complete with the three bugfix ports.

## Notes
- Ignored upstream commits: CMakeLists Windows-CI fixes (`fee3b54`/`6ac428e`, SPM-only here) and CODEOWNERS (`294c2fb`).
- Per project rules: write a failing test first for each bugfix before implementing.

## Progress (2026-07-02)
- **#1232** — `Sources/SwiftiomaticKit/Rules/Idioms/NoAssignmentInExpressions.swift`: added `isInfixOperatorWithUnknownPrecedence(_:context:)`, threaded `context` into `isStandaloneAssignmentStatement`. Test harness `Tests/.../LintOrFormatRuleTestCase.swift` now folds with `foldAll(tree) { _ in }` instead of `try!`. New test `standaloneAssignmentWithCustomOperatorIsUnchanged`.
- **#1221** — `Sources/SwiftiomaticKit/Rules/Declarations/SplitMultipleDeclsPerLine.swift`: added the no-associated-value guard in the `EnumDeclSyntax` transform. New test `bareCaseElementsOnContinuationLinesAreNotDisturbed`.
- **#1233** — `Sources/SwiftiomaticKit/Rules/Sort/SortImports.swift`: added `sortComponents`/`sortName`, rewired `importPrecedes`. New test `backticksAreIgnoredWhenSorting`.
- Full suite green: **3472 passed, 0 failed**. The `foldAll` harness change affects all rule tests — verified no regressions.

## Summary of Changes
Ported three upstream swift-format bugfixes into Swiftiomatic (test-first, each with a regression test):
- **#1232** `NoAssignmentInExpressions` — no longer false-positives on standalone assignments wrapped by custom operators (`x = try f() ?! error`); the standalone-statement walk now skips enclosing infix ops absent from the operator table. Test harness folds with the error-swallowing `foldAll(_:errorHandler:)` (matching production) so custom operators can be exercised.
- **#1221** `SplitMultipleDeclsPerLine` (local equivalent of upstream `OneCasePerLine`) — cases with no associated values are left untouched, fixing continuation-line `case\n  first` collapsing to `casefirst`.
- **#1233** `SortImports` (local equivalent of `OrderedImports`) — import sorting ignores backticks, so raw-identifier module names sort by content instead of being grouped by their escaping.

Item 4 (SwiftTestingNamingConventions, a net-new rule) deferred to `iqr-ybv`. Full suite: 3472 passed, 0 failed.
