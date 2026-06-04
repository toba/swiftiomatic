---
# bx5-5jx
title: 'CollapseSimpleEnums: allow collapsing enums with explicit raw values'
status: completed
type: bug
priority: normal
created_at: 2026-06-04T16:48:39Z
updated_at: 2026-06-04T16:51:46Z
sync:
    github:
        issue_number: "721"
        synced_at: "2026-06-04T16:53:17Z"
---

The rule currently skips any enum case with an explicit raw value (`= 1`), so:

```swift
@SQLEntity public enum GoalMetric: Int, CaseIterable, Sendable {
    case wordCount = 1
}
```

is left expanded. Expected:

```swift
@SQLEntity public enum GoalMetric: Int, CaseIterable, Sendable { case wordCount = 1 }
```

Decision: collapse enums with explicit raw values regardless of case count (single \`case low = 0, high = 1\` form). Remove the rawValue check in `isCollapsible` and update the existing `skipsRawValues` test to expect collapse.

- [x] Add failing test reproducing the user's case
- [x] Remove rawValue skip in `isCollapsible`
- [x] Update `skipsRawValues` test to expect collapse
- [x] Update doc comment
- [x] Run filtered tests



## Summary of Changes

- `Sources/SwiftiomaticKit/Rules/Wrap/CollapseSimpleEnums.swift`: dropped the `element.rawValue != nil` skip in `isCollapsible`, so enums with explicit raw values now collapse; switched the length probe to `element.trimmedDescription` so the `= value` text is included in the line-length budget; updated the doc comment.
- `Tests/SwiftiomaticTests/Rules/Wrap/CollapseSimpleEnumsTests.swift`: renamed `skipsRawValues` → `collapsesExplicitRawValues` with collapse expectations, and added `collapsesSingleCaseWithRawValueAndAttribute` reproducing the user's `@SQLEntity public enum GoalMetric: Int, CaseIterable, Sendable { case wordCount = 1 }` case.
- Full suite: 3438 passed, 0 failed.
