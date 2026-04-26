---
# p3a-udo
title: ReflowComments breaks DocC '``Symbol``' references with stray spaces
status: review
type: bug
priority: high
created_at: 2026-04-26T21:49:14Z
updated_at: 2026-04-26T21:49:14Z
sync:
    github:
        issue_number: "460"
        synced_at: "2026-04-26T22:01:42Z"
---

## Problem

ReflowComments tokenizer treats DocC double-backtick symbol references (````Foo/bar()````) as three separate atoms: opening ````````, the symbol path, and closing ````````. The wrapper then inserts spaces between them and may even break a line between ```````` and the symbol.

## Reproduce

Input:
```swift
/// if they want to clear their local data or not, implement this method, and explicitly call
/// ``SyncEngine/deleteLocalData()`` if/when the data should be cleared.
```

Output:
```swift
/// if they want to clear their local data or not, implement this method, and explicitly call ``
/// SyncEngine/deleteLocalData() `` if/when the data should be cleared.
```

The ```````` opener is split from its content and a space appears before the closer.

## Root cause

`Sources/SwiftiomaticKit/Rules/Comments/CommentReflowEngine.swift` `tokenize` (line ~347): when it sees a backtick, it scans for the FIRST closing backtick. With ````````, the second opening backtick closes the atom immediately — yielding the empty atom ````````. The remaining symbol and trailing closer become separate atoms.

## Fix

Match a run of N opening backticks against a run of exactly N closing backticks (CommonMark inline-code rule).

## Tasks

- [x] Add tokenizer test for DocC ````Symbol```` references
- [x] Add reflow test that confirms the reference stays whole after wrapping
- [x] Update tokenizer to match N-backtick runs
- [ ] Run test suite (blocked: unrelated compile error in RewriteCoordinator.swift)
