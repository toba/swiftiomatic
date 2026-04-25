---
# axa-3eo
title: singleLineBodies inline doesn't collapse for-in body that fits on one line
status: completed
type: bug
priority: normal
created_at: 2026-04-25T20:04:05Z
updated_at: 2026-04-25T20:30:22Z
sync:
    github:
        issue_number: "414"
        synced_at: "2026-04-25T22:35:07Z"
---

## Problem

When `singleLineBodies` is set to `inline`, a `for-in` loop with a single-statement body that would fit on one line is not being collapsed.

## Example

This input:

```swift
for ruleName in ruleNames {
    ruleMap[ruleName, default: []].append(sourceRange)
}
```

should be formatted as:

```swift
for ruleName in ruleNames { ruleMap[ruleName, default: []].append(sourceRange) }
```

when it fits within the configured line width.

## Tasks

- [x] Add failing test reproducing the issue (for-in with single statement, fits on one line, `singleLineBodies: inline`)
- [x] Locate the singleLineBodies inline handling and identify why for-in is skipped
- [x] Implement fix
- [x] Confirm test passes
- [x] Verify no regressions in other singleLineBodies tests



## Summary of Changes

The bug wasn't specific to for-in — it affected every inline visitor (if/guard/for/while/repeat/function/init/subscript/property/observer) but only manifested at exactly the `lineLength` boundary. Existing tests had generous slack so it was never hit.

### Root cause

`fitsInline(prefixLength:bodyText:suffixLength:)` in `Sources/SwiftiomaticKit/Rules/Wrap/WrapSingleLineBodies.swift` double-counted the `{` character. `prefixLength(from:to:)` returns a count that *includes* `{` (both the Allman and non-Allman branches), but the formula then added `+ 2` for `"{ "`, counting the brace twice. For a line that collapses to exactly 100 chars at `lineLength = 100`, the formula computed 101 and rejected it.

### Fix

One-line change in `fitsInline`: replace `+ 2` (for `"{ "`) with `+ 1` (just the trailing space), since `{` is already in `prefixLength`. This corrects all 10 callers.

### Files changed

- `Sources/SwiftiomaticKit/Rules/Wrap/WrapSingleLineBodies.swift` — fix in `fitsInline` (lines 444-452).
- `Tests/SwiftiomaticTests/Rules/Wrap/SingleLineBodiesTests.swift` — added `forLoopInlinesAtExactLineLengthBoundary` test using `lineLength = 29` so the collapsed form is exactly 29 chars.

### Verification

`swift_package_test --filter SingleLineBodies` → 78 passed, 0 failed.

The real-world case in `Sources/SwiftiomaticKit/Syntax/RuleMask.swift:224` (the for-in over `ruleNames` at 20 spaces of indent, collapsed line is exactly 100 chars) will now inline at the user's configured `lineLength: 100`.
