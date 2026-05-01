---
# t8p-jfj
title: Doc-comment reflow merges Markdown footnote definitions into prose
status: completed
type: bug
priority: normal
created_at: 2026-05-01T22:14:55Z
updated_at: 2026-05-01T23:10:52Z
sync:
    github:
        issue_number: "613"
        synced_at: "2026-05-01T23:12:04Z"
---

The doc-comment reflow rule treats a footnote/link reference definition as a regular continuation paragraph and reflows it onto the previous line, breaking the Markdown.

## Reproduction

Input:

```
/// Text view for [iOS][uiv] or [MacOS][nsv]
///
/// [uiv]: https://developer.apple.com/documentation/uikit/uitextview
/// [nsv]: https://developer.apple.com/documentation/appkit/nstextview
```

Output:

```
/// Text view for [iOS][uiv] or [MacOS][nsv]
///
/// [uiv]: https://developer.apple.com/documentation/uikit/uitextview [nsv]:
/// https://developer.apple.com/documentation/appkit/nstextview
```

The reflow joins the two `[name]: url` definitions into a single line, which makes them invalid Markdown link references. Footnote/reference definitions of the form `[label]: url` (with optional title) must remain on their own line.

## Tasks

- [x] Find the doc-comment reflow rule and locate where paragraph wrapping decides what counts as a continuation line
- [x] Add a failing test that exercises the `[label]: url` line pattern across two adjacent definition lines and asserts no reflow
- [x] Treat `^\s*\[[^\]]+\]:\s` (CommonMark link/reference definition) as a hard break — never merge into the previous or next line, never wrap mid-URL
- [x] Re-run the reflow rule's test suite and full suite



## Summary of Changes

`Sources/SwiftiomaticKit/Rules/Comments/CommentReflowEngine.swift`: added `isLinkReferenceDefinition(_:)` that recognizes a CommonMark link reference definition (optional 0–3 leading spaces, `[label]: dest`). `parseBlocks` now (a) emits such a line as a `.verbatim` block at the top-level dispatch, and (b) breaks paragraph collection when one is encountered, so adjacent definitions can never be folded into a single paragraph and reflowed.

Added regression test `preservesAdjacentLinkReferenceDefinitions` in `Tests/SwiftiomaticTests/Rules/ReflowCommentsTests.swift` covering the exact reproduction (two `[uiv]:` / `[nsv]:` lines after a paragraph). Full suite passes (3162 tests).
