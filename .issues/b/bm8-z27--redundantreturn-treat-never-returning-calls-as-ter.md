---
# bm8-z27
title: 'RedundantReturn: treat Never-returning calls as terminal branches'
status: completed
type: feature
priority: normal
created_at: 2026-04-24T01:48:21Z
updated_at: 2026-04-24T01:51:22Z
sync:
    github:
        issue_number: "365"
        synced_at: "2026-04-24T02:26:01Z"
---

## Context

`RedundantReturn` handles exhaustive if/switch where every branch has `return <expr>`, but doesn't recognize branches ending in `Never`-returning calls (`fatalError`, `preconditionFailure`) as terminal. This means `return` isn't stripped from sibling branches.

Example from `Selection.swift`:
```swift
func overlapsOrTouches(_ range: Range<AbsolutePosition>) -> Bool {
    switch self {
        case .infinite:
            return true  // ← return should be strippable
        case .ranges(let ranges):
            return ranges.contains { $0.overlapsOrTouches(range) }  // ← same
        case .unresolvedLineRanges:
            fatalError("Must resolve Selection before calling overlapsOrTouches")
    }
}
```

## Tasks

- [x] Add \`isFatalCall\` helper to recognize \`fatalError\`/\`preconditionFailure\` calls
- [x] Update \`branchReturns\` to accept fatal branches as terminal
- [x] Update \`stripBranch\` to leave fatal branches unchanged
- [x] Add tests for switch with fatalError branch, if/else with preconditionFailure
- [x] Verify no regressions in existing tests


## Summary of Changes

Extended RedundantReturn to recognize Never-returning calls (fatalError, preconditionFailure) as terminal branches. Added isFatalCall helper, updated branchReturns and stripBranch, 3 new tests. All 18 tests pass.
