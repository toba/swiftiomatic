---
# cv7-18e
title: Indent regular comment one space extra when following a doc comment
status: completed
type: feature
priority: normal
created_at: 2026-05-22T14:17:53Z
updated_at: 2026-05-22T14:31:19Z
sync:
    github:
        issue_number: "696"
        synced_at: "2026-05-22T14:36:16Z"
---

When a regular line comment (//) directly follows a doc-line comment (///) with no blank line between, indent the // comment body one extra space so it aligns with the /// body.

Example desired:
```
///
/// [apl]: https://developer.apple.com/...
//  https://docs.citationstyles.org/...
```
instead of `// https://...`.

- [x] Add test reproducing desired output
- [x] Tag line comment that immediately follows a docLine comment
- [x] Emit extra space at print time
- [x] Verify full suite


## Summary of Changes

A regular `//` line comment that directly follows a `///` doc-line comment (no blank line between) now has its body indented one extra space so it aligns with the doc comment body. Applies to the whole contiguous run of `//` comments, not just the first.

Gated behind a new `indentation` group setting `alignCommentWithAdjacentDocComment` (default `true`).

- `Comment.swift`: added `alignsWithPrecedingDocLine` flag; in `print()`, an aligned line whose body has exactly one leading space gets a second (idempotent fixed point — two spaces stay two).
- `TokenStream+Appending.swift`: in `appendToken`, when a `.line` comment follows a `.docLine` comment across a soft(1) break and the setting is enabled, set the flag. Contiguous same-kind `//` comments merge and inherit it.
- New `Rules/Indentation/AlignCommentWithAdjacentDocComment.swift` LayoutRule, default true.
- Tests in `CommentTests.swift` (enabled, disabled, multi-line block) + updated `lineWithDocLineComment`.

Full suite: 3377 passed.
