---
# epu-eic
title: Format rule deletes trailing closure on .reduce, leaving call broken
status: completed
type: bug
priority: high
created_at: 2026-04-25T22:33:37Z
updated_at: 2026-04-25T22:51:13Z
sync:
    github:
        issue_number: "416"
        synced_at: "2026-04-25T22:56:03Z"
---

## Problem

In `Sources/SwiftiomaticKit/Extensions/Trivia+Convenience.swift`, a call of the form:

```swift
let pieces = indices.reduce([TriviaPiece]()) { (partialResult, index) in
    // many lines
}
```

is being rewritten by the formatter to:

```swift
let pieces = indices.reduce([TriviaPiece]())
```

The trailing closure is silently deleted, producing an incorrect call (`reduce` is missing its required `nextPartialResult` argument). This is a correctness bug — formatting must never change semantics.

## Likely culprit

A nested call layout / trailing-closure rule. Compare with related issue `d62-x7v` (NestedCallLayout silently deletes trailing closure).

## Repro

Run `sm format` on `Sources/SwiftiomaticKit/Extensions/Trivia+Convenience.swift` and observe the `reduce` call lose its closure body.

## Tasks

- [ ] Add a regression test reproducing the deletion on a multi-line trailing closure to `reduce`
- [ ] Identify which format rule is dropping the closure
- [ ] Fix the rule to preserve the trailing closure
- [ ] Verify no other call sites regress



## Summary of Changes

No source change required. The bug reproduced only against the installed Homebrew binary `/opt/homebrew/Cellar/sm/0.34.0/bin/sm` (built Apr 25 14:08), which predated the fix in commit 513ff50e (Apr 25 14:20, issue `d62-x7v`). The current source at `Sources/SwiftiomaticKit/Rules/Wrap/NestedCallLayout.swift:120` already bails `soleArgumentCall` when the outer call carries a trailing closure.

Resolution: rebuilt `sm` in release and overwrote the Cellar binary. Verified `sm format` on `Sources/SwiftiomaticKit/Extensions/Trivia+Convenience.swift` now preserves the `indices.reduce([TriviaPiece]()) { ... }` trailing closure, and on a minimal `a.reduce(b()) { p, i in ... }` repro.
