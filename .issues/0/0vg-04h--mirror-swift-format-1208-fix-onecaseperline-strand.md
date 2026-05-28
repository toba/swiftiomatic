---
# 0vg-04h
title: 'Mirror swift-format #1208: fix OneCasePerLine stranding the case keyword'
status: completed
type: bug
priority: normal
created_at: 2026-05-28T13:11:37Z
updated_at: 2026-05-28T13:26:28Z
sync:
    github:
        issue_number: "712"
        synced_at: "2026-05-28T13:43:08Z"
---

Upstream swift-format commit fffd8df6 (PR #1208) fixes OneCasePerLine: when the elements of a multi-element case declaration are spread across continuation lines (each element after a trailing comma on its own line), splitting them into separate case declarations left a leading newline on the element name. With respectsExistingLineBreaks enabled (the default), the pretty printer honored that newline and emitted:

    case
      b = 1

instead of:

    case b = 1

Fix: drop the leading vertical whitespace from the first element of each generated case declaration while preserving comments.

Comment handling refinements:
- A doc/leading comment that documents a binding on a continuation line is hoisted to precede the new 'case' keyword (instead of being stranded between 'case' and the binding name).
- An end-of-line comment on the previous binding stays attached to that binding rather than migrating to the new case.
- Removing a trailing comma previously discarded the comma's trailing trivia, losing end-of-line comments like 'case a = 1,  // about a'. That trivia is now preserved on the element.

## Tasks

- [x] Locate Swiftiomatic's OneCasePerLine equivalent (SplitMultipleDeclsPerLine)
- [x] Reproduce the stranded-case bug in a test (with respectsExistingLineBreaks enabled)
- [x] Port the fix from swift-format fffd8df6
- [x] Add tests for: hoisted leading comment, retained end-of-line comment, both combined on a single split
- [x] Run filtered tests, then full suite (3411 passed)

## References

- swift-format commit: https://github.com/swiftlang/swift-format/commit/fffd8df6153456838039aae4b9b901f6f31f5687
- Reference clone: ~/Developer/swiftiomatic-ref/swift-format/Sources/SwiftFormat/Rules/OneCasePerLine.swift


## Summary of Changes

Ported swift-format PR #1208 into Swiftiomatic. The equivalent rule in this fork is `SplitMultipleDeclsPerLine` (which only splits associated-value cases, but suffers the same continuation-line bug as upstream `OneCasePerLine`).

- `Sources/SwiftiomaticKit/Extensions/Trivia+Convenience.swift`: added `Trivia.splittingLeadingComments() -> (hoisted: Trivia, remainder: Trivia)` plus two private static helpers (`isCommentPiece`, `isWhitespace`).
- `Sources/SwiftiomaticKit/Rules/Declarations/SplitMultipleDeclsPerLine.swift`:
  - Added `CaseElementCollector.removeTrailingComma(from:)` that drops the trailing comma but keeps any end-of-line comment that the comma was carrying.
  - Switched `makeCaseDeclAndReset` and the inner `basisElement.trailingComma = nil` site to use the new helper.
  - In `makeCaseDeclFromBasis`, the first element's leading trivia is now split via `splittingLeadingComments()`: whitespace is dropped (so the element sits on the same line as `case`), and any documentation comment is hoisted to precede the newly inserted `case` keyword, separated by a newline.

Tests: added 4 new `@Test` methods to `SplitMultipleDeclsPerLineTests` covering the bare continuation-line bug, leading documentation comment, end-of-line comment, and both combined. All 15 tests in that suite pass, and the full suite (3411 tests) is green.
