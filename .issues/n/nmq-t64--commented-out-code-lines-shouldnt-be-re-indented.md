---
# nmq-t64
title: Commented-out code lines shouldn't be re-indented
status: completed
type: bug
priority: normal
created_at: 2026-04-26T02:58:40Z
updated_at: 2026-04-26T04:07:22Z
sync:
    github:
        issue_number: "445"
        synced_at: "2026-04-26T04:09:22Z"
---

## Problem

The formatter indents lines inside commented-out code blocks as if they were live code. Lines that are entirely `//`-prefixed comments should be left at whatever indentation the author chose; they shouldn't be aligned to the surrounding scope's indentation level.

## Repro

```swift
public extension KeyedDecodingContainer {
//    func decode<T: Decodable>(_ key: Key) throws -> T {
//        try decode(T.self, forKey: key)
//    }

//    func decode<T: DecodableWithConfiguration>(
//        _ key: Key,
//        with configuration: T.DecodingConfiguration
//    ) throws -> T {
//        try decode(T.self, forKey: key, configuration: configuration)
//    }
}
```

Currently, the formatter re-indents every `//` line to match the body's indentation. Expected: leave commented-out lines untouched (or at least don't force-indent them).

## Tasks

- [x] Add a failing test case with commented-out code at column 0 inside a scoped declaration
- [x] Identify which format rule / token-stream pass is re-indenting line comments
- [x] Fix so leading line-comment-only lines preserve their original column
- [x] Verify doc comments (`///`) and trailing comments are unaffected


## Summary of Changes

**Root cause:** In `LayoutCoordinator.swift`, every `.comment` token was written via `LayoutBuffer.write`, which lazily flushes `currentIndentation` (the surrounding scope's indent) at the start of each new line. The `Comment.leadingIndent` value already captured the source column for standalone line comments (set by trivia walk in `TokenStream+Appending.swift:139,175-181`) but was only consulted for block comments.

**Fix:** In `Sources/SwiftiomaticKit/Layout/LayoutCoordinator.swift` `.comment` case, when the token is a standalone `.line` comment with `leadingIndent` and the buffer is at start-of-line, temporarily swap `outputBuffer.currentIndentation` to `[leadingIndent]` for the write, then restore. This preserves the author's original column for any standalone `//` line without affecting trailing comments, doc comments, or block comments.

**Test:** Added `standaloneLineCommentsPreserveOriginalColumn` to `Tests/SwiftiomaticTests/Layout/CommentTests.swift` covering the reproduction from the bug report.

**Verification status:** Could not execute the test suite this session — an unrelated, pre-existing compile error in `Sources/SwiftiomaticKit/Extensions/Trivia+Convenience.swift` (in-progress work by another agent, file outside this task's scope) blocks the SPM lint build-tool plugin and therefore all builds. Once that file compiles, `swift test --filter CommentTests` should be run to confirm the new test passes and no existing comment tests regress.
