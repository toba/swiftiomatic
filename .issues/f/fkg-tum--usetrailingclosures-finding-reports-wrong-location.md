---
# fkg-tum
title: useTrailingClosures finding reports wrong location (line 1) for nested calls
status: completed
type: bug
priority: normal
created_at: 2026-05-02T18:43:10Z
updated_at: 2026-05-02T18:51:18Z
sync:
    github:
        issue_number: "636"
        synced_at: "2026-05-02T18:52:15Z"
---

Reported by user: in /Users/jason/Developer/toba/thesis/Core/Sources/Storage/CustomFunctions.swift, the useTrailingClosures finding shows up at line 1 (which is `public import GRDB`) instead of at the actual function call.

## Root cause

In Sources/SwiftiomaticKit/Syntax/Rewriter/RewritePipeline.swift around line 786, `UseTrailingClosures.apply` is called with the result of `super.visit(node)` (a `FunctionCallExprSyntax` whose children have been rewritten by SwiftSyntax). That node is detached from the original tree — its `position` is 0 relative to its own root. `SyntaxRule.diagnose` calls `node.startLocation(converter: context.sourceLocationConverter)` which then returns line 1, column 1 (offset 0 of the original file).

Other rules in the same dispatch (HoistAwait, HoistTry, etc.) receive both the rewritten `concrete` node and the `original` node, and pass `original` for finding location. `UseTrailingClosures.apply` does not.

## Fix

- [ ] Add a test reproducing the wrong location (call on line >1)
- [ ] Pass the original `node` to `UseTrailingClosures.apply` and use it as the finding anchor in `convertSingle` and `convertMultiple`
- [ ] Verify the fix



## Summary of Changes

- Sources/SwiftiomaticKit/Rules/Closures/UseTrailingClosures.swift — added `original: FunctionCallExprSyntax` parameter to `apply`, `convertSingle`, and `convertMultiple`. The diagnose call now anchors on the original (pre-`super.visit`) node instead of the rewritten `callNode`, which is detached and reports position 0 (line 1, col 1).
- Sources/SwiftiomaticKit/Syntax/Rewriter/RewritePipeline.swift — pass `original: node` through to `UseTrailingClosures.apply`, mirroring the pattern already used by `HoistAwait` / `HoistTry` / `UseSwiftTestingNotXCTest`.
- Tests/SwiftiomaticTests/Rules/UseTrailingClosuresTests.swift — added `findingLocationUsesOriginalNodePosition` regression test.

Verified against the originally-reported file: finding moved from line 1 col 10 to line 9 col 9 (the actual `sqlite3_create_function_v2` call). Full TrailingClosuresTests suite (43 tests) passes.
