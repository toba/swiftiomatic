---
# gbg-s72
title: Member-access chain inside call argument over-indents continuation by one level
status: completed
type: bug
priority: high
created_at: 2026-05-28T13:33:53Z
updated_at: 2026-05-28T13:42:11Z
sync:
    github:
        issue_number: "711"
        synced_at: "2026-05-28T13:43:09Z"
---

## Repro

```swift
import SwiftUI

struct MissingFigureView: View {
    var body: some View {
        VStack {
            Text("x")
        }
        .overlay(RoundedRectangle(cornerRadius: 6)
            .strokeBorder(Color.gray.opacity(0.4), style: StrokeStyle(lineWidth: 1, dash: [4])),
        )
    }
}
```

After `sm format`, the `.strokeBorder(...)` line is indented one level too far (16 spaces instead of 12). The continuation of a member-access chain that appears as a call argument should align with the argument start (which itself is on a continuation line), not double-continue.

## Expected

`.strokeBorder` indented at 12 spaces (one continuation level inside the call), matching where `RoundedRectangle` started.

## Actual

`.strokeBorder` indented at 16 spaces (two continuation levels).

## Tasks

- [x] Add failing test in PrettyPrintTests covering this shape
- [x] Locate over-indent (likely member-access chain inside call-argument list interacting with continuation indent)
- [x] Fix and confirm test passes
- [x] Run full suite for regressions



## Summary of Changes

- `isCompactSingleFunctionCallArgument` in `Sources/SwiftiomaticKit/Layout/Tokens/TokenStream+Appending.swift` no longer treats a `FunctionCallExpr` argument as compact when its called expression is a member-access chain whose base is itself a calling expression (function call / subscript). The earlier blanket inclusion of `FunctionCallExprSyntax` (added in `edef36bd`) was over-broad: for chains like `RoundedRectangle(cornerRadius: 6).strokeBorder(...)`, the hug suppressed the outer arg-list break while the chain dot break still applied its own continuation indent, compounding to two levels and over-indenting the chain step.
- Single-step inner calls (`foo(bar.baz(...))`, `foo(.implicitMember(...))`) remain compact — only multi-step chains rooted on a function-call base are excluded.
- Added regression test `multiStepChainAsSingleArgumentIndentsOneLevel` in `Tests/SwiftiomaticTests/Layout/FunctionCallTests.swift`.
- Updated `assignmentWithChainAsCallArgumentFitsOnOneLine` in `Tests/SwiftiomaticTests/Layout/AssignmentExprTests.swift` to the upstream-aligned shape (the outer `.init(` arg list wraps; the chain stays intact on one indented line).
- Full suite: 3412 passed, 0 failed.
