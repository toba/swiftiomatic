---
# at4-xyc
title: 'Add CollapseSimpleChains rule: collapse multiline member-access chains to one line when they fit'
status: completed
type: feature
priority: normal
created_at: 2026-05-23T19:06:09Z
updated_at: 2026-05-23T19:19:10Z
sync:
    github:
        issue_number: "703"
        synced_at: "2026-05-23T19:20:56Z"
---

## Goal

Implement a new `CollapseSimpleChains` `StaticFormatRule` that collapses multi-line member-access chains onto a single line when the collapsed form fits the line limit.

## Example

Before:
```swift
try SyncRemindersList
    .find(1)
    .delete(from: db)
```

After:
```swift
try SyncRemindersList.find(1).delete(from: db)
```

## Tasks

- [x] Create `Sources/SwiftiomaticKit/Rules/Wrap/CollapseSimpleChains.swift`
- [x] Register in `RewritePipeline.swift` (FunctionCallExprSyntax visitor, after WrapMultilineFunctionChains)
- [x] Create `Tests/SwiftiomaticTests/Rules/Wrap/CollapseSimpleChainsTests.swift`
- [x] Run generate-swiftiomatic and build/test

## Summary of Changes

Added `CollapseSimpleChains` — a new `StaticFormatRule` (off by default) that collapses multi-line member-access chains onto a single line when the collapsed form fits within the configured line length. Dispatched from `RewritePipeline.visit(_: FunctionCallExprSyntax)` after `WrapMultilineFunctionChains`. Guards against: inner newlines (multiline args/closures), comments anywhere in the chain, chains that extend beyond via trailing property access (to avoid partial collapsing), and chains too long for the line limit. Uses a single-pass `SyntaxRewriter` to strip all wrapped periods' leading trivia in one traversal (avoids `SyntaxIdentifier` invalidation across multiple rewrites). 8 tests, 3391 total passing.
