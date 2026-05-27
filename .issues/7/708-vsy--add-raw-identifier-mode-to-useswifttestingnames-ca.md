---
# 708-vsy
title: Add raw-identifier mode to UseSwiftTestingNames (camelCase → `name with spaces`)
status: completed
type: feature
priority: normal
created_at: 2026-05-27T18:33:17Z
updated_at: 2026-05-27T18:38:21Z
sync:
    github:
        issue_number: "710"
        synced_at: "2026-05-27T18:39:51Z"
---

SwiftFormat's swiftTestingTestCaseNames rule supports a raw-identifiers mode that converts camelCase @Test function names into backtick-wrapped raw identifiers with spaces (func testFooBar() -> func `foo bar`()). Our UseSwiftTestingNames only strips the 'test' prefix. Add an option to support the raw-identifier transformation.

- [x] Write failing tests for raw-identifier conversion
- [x] Add config option (style/mode) to the rule
- [x] Implement camelCase -> spaced backtick conversion
- [x] Verify full suite passes


## Summary of Changes

Added a `style` option to `UseSwiftTestingNames` (config type changed from `BasicRuleValue` to new `SwiftTestingNamesConfiguration`):

- `.standardIdentifier` (default) — existing behavior: strip the `test` prefix → camelCase.
- `.rawIdentifier` — convert camelCase `@Test` names to backtick raw identifiers with spaces (`testMyFeatureHasNoBugs` → `` `my feature has no bugs` ``). Drops a leading `test` word, splits camelCase/PascalCase/acronym/digit boundaries, lowercases words, skips already-backticked and purely-numeric results.

Matches SwiftFormat's `swiftTestingTestCaseNames` raw-identifiers/standard-identifiers modes. Two new tests added; full suite 3402 passing.
