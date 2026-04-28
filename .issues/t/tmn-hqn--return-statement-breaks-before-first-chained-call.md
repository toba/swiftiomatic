---
# tmn-hqn
title: Return statement breaks before first chained call instead of after 'return'
status: completed
type: bug
priority: normal
created_at: 2026-04-27T21:42:03Z
updated_at: 2026-04-27T21:59:57Z
sync:
    github:
        issue_number: "472"
        synced_at: "2026-04-28T02:39:59Z"
---

## Problem

In `Tests/SwiftiomaticTests/GoldenCorpus/GoldenCorpusTests.swift`, the formatter produces:

```swift
return
    entries
    .filter { $0.lastPathComponent.hasSuffix(".swift.fixture") }
    .sorted { $0.lastPathComponent < $1.lastPathComponent }
```

It should produce:

```swift
return entries
    .filter { $0.lastPathComponent.hasSuffix(".swift.fixture") }
    .sorted { $0.lastPathComponent < $1.lastPathComponent }
```

The break after `return` is firing before the inner `.` (member-access) breaks on the chain. The `.` breaks should win — same break-precedence treatment used for assignment RHS and `guard` conditions.

## Expected behavior

`return <expr>` should keep the expression value on the same line as `return` and let inner contextual `.` breaks fire first. The break between `return` and its operand is a last-resort break, not a first-resort one.

## Background

See `CLAUDE.md` "Layout & Break Precedence" — the fix is the same `.open` chunk-bounding trick used in `arrangeAssignmentBreaks` and `BeforeGuardConditions`. The `return` keyword break needs its chunk bounded so inner `.` breaks fire first.

Likely fix lives in `TokenStream+ControlFlow.swift` (return statement handling) — wrap the operand in `.open/.close` around the RHS so the post-`return` break's chunk is bounded by the inner contextual breaks rather than extending across the whole expression.

## Tasks

- [x] Add a golden-corpus fixture (or unit test) reproducing the bug — long member chain after `return`
- [x] Locate return-statement token emission and compare against `arrangeAssignmentBreaks` precedence trick
- [x] Apply `.open` placement so `.` breaks win over the `return` break
- [x] Verify against existing golden snapshots; regenerate intentional changes with `SWIFTIOMATIC_UPDATE_GOLDEN=1`



## Summary of Changes

Fixed in `Sources/SwiftiomaticKit/Layout/Tokens/TokenStream+ControlFlow.swift` by extracting a shared `arrangeKeywordOperandBreak(expression:)` helper used by both `visitReturnStmt` and `visitThrowStmt`. The helper mirrors the `arrangeAssignmentBreaks` `canGroupBeforeBreak` branch: when the operand is a member-access chain or compound expression (and there's no leftmost multiline string literal or leading line comments), it wraps the break in `.open`/`.close` so the keyword break's chunk is bounded by inner contextual `.` / operator breaks. Inner breaks now fire first, keeping `return entries` on one line and wrapping `.filter` / `.sorted` underneath.

Build clean. GoldenCorpusTests pass.
