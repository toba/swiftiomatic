---
# mcp-hgl
title: ReflowComments skips commented-out code
status: completed
type: bug
priority: normal
created_at: 2026-06-07T17:15:47Z
updated_at: 2026-06-07T17:33:08Z
sync:
    github:
        issue_number: "722"
        synced_at: "2026-06-07T19:20:33Z"
---

Comment reflow re-wraps lines that are clearly commented-out code (e.g., SwiftUI snippets with braces and indented bodies), corrupting them. Skip the entire `//` run when:

1. Any line in the run contains `{` or `}`, or
2. At least two lines in the run start with 4+ spaces after the comment prefix (indented code block).

- [x] Add failing test reproducing the SwiftUI ToolbarItem case
- [x] Implement guard in ReflowComments.reflow
- [x] Confirm full suite passes



## Summary of Changes

- `Sources/SwiftiomaticKit/Rules/Comments/ReflowComments.swift`: added `looksLikeCommentedOutCode(_:)` and a `.line`-only guard in `reflow(_:context:)` that skips an entire contiguous `//` run when (1) any body line contains `{` or `}`, or (2) at least two body lines start with 4+ spaces after the prefix. `///` doc comments are unaffected.
- `Tests/SwiftiomaticTests/Rules/ReflowCommentsTests.swift`: three new tests — braced commented-out SwiftUI block, braceless indented code block, prose with incidental brace (codifies the conservative choice).
- Full suite: 3441 passed, 0 failed.
