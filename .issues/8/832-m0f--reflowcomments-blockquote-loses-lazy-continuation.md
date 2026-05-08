---
# 832-m0f
title: 'ReflowComments: blockquote loses lazy continuation lines'
status: completed
type: bug
priority: normal
created_at: 2026-05-08T06:22:40Z
updated_at: 2026-05-08T06:34:09Z
---

## Bug

Doc-comment reflow drops the blockquote prefix on continuation lines that don't start with `>`. CommonMark allows lazy continuation: a paragraph inside a blockquote can be continued on subsequent lines without a leading `>`. Swiftiomatic's reflow engine treats those lines as a separate paragraph, so the blockquote indent (`> ` / `  ` lazy indent) is lost.

### Repro

Input:
```swift
/// > Developer Note: Conformance to [CodingKeyRepresentable][hck] is essential to have the `Values`
///   JSON encoder produce a JavaScript object, es expected, rather than an array of [alternating
///   key-value pairs][frm].
```

Buggy output (continuation indent collapses to a single space; blockquote membership lost):
```swift
/// > Developer Note: Conformance to [CodingKeyRepresentable][hck] is essential to have the `Values`
/// JSON encoder produce a JavaScript object, es expected, rather than an array of [alternating
/// key-value pairs][frm].
```

Expected: continuation lines stay inside the blockquote and align under the text after `> ` (two-space lazy indent).

## Root cause

`Sources/SwiftiomaticKit/Rules/Comments/CommentReflowEngine.swift` `parseBlocks` only collects lines that start with `>` into the blockquote (line 148-159). Lazy continuation lines fall through to the paragraph branch, which strips leading whitespace and emits them with no blockquote prefix.

The renderer (line 80-97) is fine — it already emits `> ` for the first line of each non-blank run and `  ` (two-space lazy indent) for continuations.

## Plan

- [x] Add failing test in `ReflowCommentsTests` covering blockquote with lazy continuation lines
- [x] Update `parseBlocks` to consume lazy continuation lines (non-blank, not a list/fence/link-ref/new blockquote-with-stronger-prefix line) as part of the blockquote
- [x] Run filtered tests, then full suite



## Summary of Changes

- `Sources/SwiftiomaticKit/Rules/Comments/CommentReflowEngine.swift` — `parseBlocks` blockquote branch now also consumes CommonMark lazy-continuation lines (non-blank, not a list/fence/link-ref). Previously only `>`-prefixed lines were collected, so subsequent indented lines escaped the blockquote and lost the `> ` / 2-space lazy indent.
- `Tests/SwiftiomaticTests/Rules/ReflowCommentsTests.swift` — added 3 tests covering lazy continuation in single- and multi-paragraph blockquotes, including the exact body lines from the user report.
- All 29 `ReflowCommentsTests` pass; 53 comment-related tests pass; full suite has 5 unrelated failures in `VariableDecl`/`ArrayDecl`/`PatternBinding` from the in-progress generic-argument tuple wrapping work on `TokenStream+Bindings.swift` (issue `ke5-6mj`).
