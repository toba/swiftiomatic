---
# 487-2dd
title: Formatter absorbs case-body statement into trailing comment on multi-pattern case
status: completed
type: bug
priority: normal
created_at: 2026-07-08T17:05:02Z
updated_at: 2026-07-08T17:18:53Z
sync:
    github:
        issue_number: "753"
        synced_at: "2026-07-08T17:19:39Z"
---

The formatter mangled `PredicateFilterValidator.swift` on the first pass: it absorbed the `continue` statement into a trailing comment (`0x5F:  // _ continue`), leaving an empty `case` body that would not compile.

## Repro

A `switch` with a multi-pattern `case` where each pattern carries an aligned inline comment, and the case body is a single statement on the following line:

```swift
switch scalar.value {
    case 0x30...0x39,  // 0-9
         0x41...0x5A,  // A-Z
         0x61...0x7A,  // a-z
         0x2E,         // .
         0x2D,         // -
         0x5F:         // _
        continue
    default: throw .invalidValue(field: field, value: value)
}
```

After `sm format -i` the formatter reflows the aligned inline comments onto their own lines AND merges the body `continue` into the final pattern's trailing comment:

```swift
switch scalar.value {
    case 0x30...0x39,  // 0-9
         0x41...0x5A,
    // A-Z
         0x61...0x7A,
    // a-z
         0x2E,
    // .
         0x2D,
    // -
         0x5F:  // _ continue   <-- 'continue' swallowed into the comment
    default: throw .invalidValue(field: field, value: value)
}
```

The `continue` is now part of the comment, so the `case` has an empty body — a compile error ('case' label in a 'switch' must have at least one executable statement).

## Impact

Silent miscompile introduced by formatting. High severity: the formatter must never move a statement into a comment or otherwise change executable code.

## Likely cause

When a labeled multi-pattern `case` line ends with a trailing comment and the case body is on the next physical line, the comment-reflow pass appears to consume the following body line as a continuation of the trailing comment.

## Workaround

Collapse the pattern list onto one line and move per-pattern documentation into a leading comment above the `case`, which is format-stable.



## Summary of Changes

**Root cause.** `appendAfterTokensAndTrailingComments` (`TokenStream+Handling.swift`) glues a trailing line comment to its token by extracting it before the first *break-that-fires-a-newline* in the token's after-group. Following upstream, it treated a non-mandatory `.break(.close(mustBreak: false))` as *not* newline-forcing and left the comment after it. That assumption breaks for the `AlignWrappedConditions` feature: each wrapped case item emits a `.break(.close)` (closing the previous item's alignment scope) immediately before the `.break(.open(.alignment))` that opens the next one. The close break still fires a newline at layout time, so the trailing comment was stranded on its own de-indented line — and at tighter line lengths the case body statement (`continue`) was pulled up into that comment, emptying the case body and producing a compile error.

**Fix.** When a line comment's after-group contains any extractable (newline-firing) break, glue the comment before the *first* break in the group — so a leading non-mandatory align-close break no longer strands it. Groups with only a lone non-mandatory close break keep the previous (upstream) behavior. Extracted the break/printerControl test into `isExtractableForTrailingComment`.

**Test.** Added `SwitchStmtTests/switchCaseMultiPatternTrailingCommentsPreserveBody` — a multi-pattern case where every pattern carries a trailing line comment and the body is on the next line; asserts the comments stay end-of-line and the body statement is preserved. Full suite green (3481 passed).
