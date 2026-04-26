---
# 82p-wbz
title: ReflowComments over-indents '- Parameters:' sub-items
status: review
type: bug
priority: high
created_at: 2026-04-26T21:39:10Z
updated_at: 2026-04-26T21:49:23Z
sync:
    github:
        issue_number: "459"
        synced_at: "2026-04-26T22:01:42Z"
---

## Problem

The comment rewriter (ReflowComments) is over-indenting nested parameter list items in doc comments. Xcode requires exactly 3 spaces before each `-` in a Parameters list; we're emitting 5 spaces, which Xcode no longer recognizes as a parameter list.

## Expected

```swift
/// - Parameters:
///   - syncEngine: The sync engine that generates the event.
///   - changeType: The iCloud account's change type.
```

## Actual

```swift
/// - Parameters:
///     - syncEngine: The sync engine that generates the event.
///     - changeType: The iCloud account's change type.
```

## Impact

Xcode Quick Help no longer renders parameter docs after formatting. Affects any DocC `- Parameters:` block.

## Tasks

- [ ] Add a failing test reproducing the over-indent on a `- Parameters:` block
- [ ] Locate the list-indent logic in ReflowComments / Markdown reflow
- [ ] Fix indent so nested list items use 3 spaces (matching the parent `- ` marker + 1)
- [ ] Verify against multi-level lists and non-Parameters bullet lists
- [ ] Run golden corpus / format suite



## Summary of Changes

`Sources/SwiftiomaticKit/Rules/Comments/CommentReflowEngine.swift` — at both nested-list recursion sites in `parseList` ("more-indented marker" branch and the in-item continuation branch), strip leading whitespace from each returned nested item's marker. The parent's `continuation` prefix is now the sole source of indentation when rendering nested blocks; previously the original leading spaces compounded with the parent prefix, doubling indent at every nesting level.

`Tests/SwiftiomaticTests/Rules/ReflowCommentsTests.swift` — added `preservesParametersBlockIndentation` (full rule test) and `preservesNestedBulletListIndentation` (engine test).

Verification blocked by an unrelated compile error in `Sources/SwiftiomaticKit/Syntax/Rewriter/RewriteCoordinator.swift` (`MultiPassRewritePipeline.rewrite` missing) from another agent's in-progress work. Logic verified by trace; test must be run once the package compiles again.
