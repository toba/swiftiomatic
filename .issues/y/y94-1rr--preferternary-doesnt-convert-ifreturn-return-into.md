---
# y94-1rr
title: PreferTernary doesn't convert if/return + return into ternary return
status: completed
type: bug
priority: normal
created_at: 2026-04-30T04:07:29Z
updated_at: 2026-04-30T04:11:30Z
sync:
    github:
        issue_number: "522"
        synced_at: "2026-04-30T04:23:38Z"
---

## Problem

When PreferTernary is enabled, the following pattern is not converted:

```swift
if validCount == 1 { return [] }
return [error("Exactly one schema in 'oneOf' must match, but \(validCount) matched")]
```

Expected output:

```swift
return validCount == 1 ? [] : [error("Exactly one schema in 'oneOf' must match, but \(validCount) matched")]
```

## Repro

Found in `Sources/SwiftiomaticKit/Configuration/SchemaValidator.swift` (validates oneOf branch).

## Tasks

- [x] Add a failing test reproducing this pattern (single-line `if cond { return X }` followed by `return Y`)
- [x] Extend PreferTernary to recognize the if-return + trailing-return pattern
- [x] Verify SchemaValidator.swift gets the conversion after the fix
- [x] Confirm existing PreferTernary tests still pass



## Summary of Changes

- `Sources/SwiftiomaticKit/Rules/Conditions/PreferTernary.swift`: extended `transform` with an index-based loop that consumes two consecutive items when the first is an `if cond { return X }` (no else, single-statement body, single-expression condition) and the second is `return Y`. New helper `tryConvertIfReturnPair` reuses existing `extractIfExpr`, `extractReturn`, and `buildTernaryExpr` helpers.
- `Tests/SwiftiomaticTests/Rules/PreferTernaryTests.swift`: added 5 tests covering single-line, multi-line, no-trailing-return, optional-binding, and multi-statement-body cases.
- All 21 PreferTernaryTests pass.
