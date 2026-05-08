---
# i9c-4c6
title: 'ReflowComments: punctuation around inline code spans gets space-separated'
status: completed
type: bug
priority: normal
created_at: 2026-05-08T06:25:54Z
updated_at: 2026-05-08T06:29:28Z
sync:
    github:
        issue_number: "656"
        synced_at: "2026-05-08T14:18:16Z"
---

## Bug

ReflowComments inserts spaces between punctuation and adjacent inline code spans (and DocC symbol references), and between a closing code span and a trailing period.

### Repro

Input:
```swift
/// Backed by the `citation_group_paragraph_indices` SQL view, which joins `citation_group` with
/// `paragraph_embedded_indices` and `node` to surface each group's containing paragraph
/// (`withinID`) and character offset within that paragraph (`characterIndex`), along with the
/// node's `render_needed` flag. Used by ``CitationGroup/fetch(forParagraph:to:from:)`` and
/// ``Citation/fetch(forParagraph:at:from:)``.
```

Buggy output:
```swift
/// (
///   `withinID`
/// ) and character offset within that paragraph ( `characterIndex` ), along with the
/// node's `render_needed` flag. Used by ``CitationGroup/fetch(forParagraph:to:from:)`` and
/// ``Citation/fetch(forParagraph:at:from:)`` .
```

Two distinct symptoms:
1. `(`withinID`)` becomes `( `withinID` )` — opening/closing parens get spaces inserted.
2. `...from:)``.` becomes `...from:)`` .` — period separated from preceding code span.

## Root cause

`CommentReflowEngine.tokenize` flushes pending text before emitting an inline-code-span / link / autolink / URL atom, then the next character (`)`, `.`, etc.) starts a new atom. The wrapper joins atoms with single spaces, inserting whitespace that wasn't in the source.

## Fix

When emitting an atomic span (backtick code, markdown link, autolink, http URL), append it to the in-progress `pending` buffer instead of flushing — so adjacent punctuation accumulates into a single atom with the span. The atom remains indivisible (won't be split mid-token) and the wrapper sees one unit instead of three.

## Plan

- [ ] Add failing test covering `(`withinID`)` and trailing punctuation cases
- [ ] Change tokenize to extend `pending` with atomic spans (don't flush before)
- [ ] Run filtered tests, then full suite



## Summary of Changes

Fixed `CommentReflowEngine.tokenize` to attach atomic spans (inline code, DocC symbol references, markdown links, autolinks, http URLs) to the in-progress `pending` buffer instead of flushing as a separate atom. Adjacent punctuation like `(`, `)`, `.`, `,` now stays glued to the span, so the wrapper no longer inserts spaces around it.

Changed: `Sources/SwiftiomaticKit/Rules/Comments/CommentReflowEngine.swift`
Added tests: `tokenizerAttachesPunctuationToInlineCodeSpan`, `reflowKeepsParensAroundCodeSpanTight` in `Tests/SwiftiomaticTests/Rules/ReflowCommentsTests.swift`
