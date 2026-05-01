---
# wy7-t4q
title: PreferTrailingClosures rewrites inside guard/if conditions, producing invalid Swift
status: completed
type: bug
priority: high
created_at: 2026-04-30T23:51:24Z
updated_at: 2026-05-01T00:31:06Z
sync:
    github:
        issue_number: "591"
        synced_at: "2026-05-01T00:49:17Z"
---

## Repro

```swift
guard arr.allSatisfy({ $0 > 0 }) else { return nil }
```

`sm format` rewrites this to:

```swift
guard arr.allSatisfy { $0 > 0 } else { return nil }
```

which Swift parses with the brace as a trailing closure to `allSatisfy`, leaving `else` orphaned. Compile fails with "expected 'else' in 'guard' statement".

## Affected files (discovered while running `sm format -r -p -i Sources/` for c12-swt)

- RedundantReturn.swift, AsyncStreamMissingTermination.swift, PreferDotZero.swift, AccessorOrder.swift, PreferSwiftTesting.swift, NoParensInClosureParams.swift, PreferTrailingClosures.swift, RewritePipeline.swift (8 sites)

## Root cause

`PreferTrailingClosures.apply(_:context:)` calls `isInConditionalContext(node)` which walks `Syntax(node).parent`. `apply` is called from `RewritePipeline.visit(_:FunctionCallExprSyntax)` with the **post-`super.visit`** `concrete` node, which has `parent == nil` (rewritten children produce a new node not yet attached to a tree). So `isInConditionalContext` always returns false → guard/if conditions are never detected → rewrite fires.

The other rules dispatched in the same visitor (`RedundantInit`, `PreferDotZero`, `HoistAwait`, etc.) use a `transform(_:parent:context:)` signature where `parent` is captured **before** `super.visit` runs. `PreferTrailingClosures.apply` is missing this parent param.

## Fix

Add `parent: Syntax?` parameter to `PreferTrailingClosures.apply` and `isInConditionalContext`, walk from `parent` instead of `Syntax(node).parent`. Update the call site in `RewritePipeline.swift:780`.

## Test infra note

`assertFormatting` with `Configuration.forTesting(enabledRule:)` does not reproduce this bug — needs investigation separately. Repro via CLI (`sm format`) is reliable.



## Summary of Changes

- `Sources/SwiftiomaticKit/Rules/Closures/PreferTrailingClosures.swift`: `apply` now takes `parent: Syntax?`. `isInConditionalContext` walks from the supplied parent instead of `Syntax(node).parent` (which is nil after `super.visit` produces a detached node).
- `Sources/SwiftiomaticKit/Syntax/Rewriter/RewritePipeline.swift`: call site updated to thread `parent` through.
- Verified via CLI: `guard arr.allSatisfy({ $0 > 0 }) else { return nil }` is now preserved instead of mangled.
- Full test suite (3139 tests) passes.

A proper regression test couldn't be added because `assertFormatting` doesn't reproduce the bug — filed as a separate issue (test infra).
