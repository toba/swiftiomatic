---
# 4pf-bov
title: Guard with multiple conditions wraps 'else' to next line instead of keeping inline
status: completed
type: bug
priority: normal
created_at: 2026-04-30T04:40:44Z
updated_at: 2026-04-30T15:30:57Z
sync:
    github:
        issue_number: "530"
        synced_at: "2026-04-30T16:27:52Z"
---

## Problem

The formatter is breaking `else { return decl }` onto its own line in multi-condition guard statements when it should keep `else` inline with the last condition (when it fits).

## Actual output

```swift
guard let mod = decl.modifiers.accessLevelModifier,
      mod.name.tokenKind == .keyword(.internal),
      mod.detail == nil
else { return decl }
```

## Expected output

```swift
guard let mod = decl.modifiers.accessLevelModifier,
      mod.name.tokenKind == .keyword(.internal),
      mod.detail == nil else { return decl }
```

## Notes

The conditions wrap (correctly, comma-separated, aligned). But the `else` clause should stay attached to the final condition rather than being forced onto its own line. Per the layout precedence rules in CLAUDE.md, guard keyword breaks are a last-resort wrap; the `else` break here should not be firing if the trailing `else { return decl }` fits on the same line as the last condition.



## Summary of Changes

Root cause: the consistent group around guard conditions force-broke. The last condition's `.break(.close, size: 0)` (with `mustBreak: false`) was processed BEFORE the consistent `.close` token, so it inherited `forceBreakStack.last == true` and fired — pushing `else` to its own line even when the inline body would fit.

Fix in `Sources/SwiftiomaticKit/Rules/LineBreaks/BeforeGuardConditions.swift`:
- Move `after(lastConditionToken, .close)` to AFTER the per-condition loop. Because `afterMap` emits groups in reverse declaration order, the consistent-group `.close` is now emitted BEFORE the last condition's close break — popping the force-break flag first so the close break (and the subsequent break before `else`) see the outer unforced state.

Tests in `Tests/SwiftiomaticTests/Layout/GuardStmtTests.swift`:
- Added `threeConditionsGlueElseWhenInlineBodyFits` (regression test, 4pf-bov).
- Updated expected output in `openBraceIsGluedToElseKeyword`, `continuationLineBreaking` (4th guard only), `attachesInlineElseToWrappedConditions`, `attachesInlineElseUnderAlignedConditions`, `breaksElseWhenInlineBodyExceedsLineLength`, `breaksElseUnderAlignedConditionsWhenBodyTooLong` to reflect the always-glue-when-inline-body-fits behavior.

All 17 GuardStmtTests pass.
