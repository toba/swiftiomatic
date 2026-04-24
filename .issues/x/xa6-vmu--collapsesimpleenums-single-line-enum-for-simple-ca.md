---
# xa6-vmu
title: 'CollapseSimpleEnums: single-line enum for simple cases'
status: review
type: feature
priority: normal
created_at: 2026-04-24T22:40:51Z
updated_at: 2026-04-24T23:01:46Z
sync:
    github:
        issue_number: "388"
        synced_at: "2026-04-24T23:31:20Z"
---

## Description

New rule in the `Wrap` group: when an enum has **no associated values**, no raw values, no conformances beyond the declaration line, no computed properties, and no methods — and all cases fit on the same line as the declaration — collapse it to a single line.

### Before

```swift
private enum OptionalPatternKind {
    case chained
    case forced
}
```

### After

```swift
private enum OptionalPatternKind { case chained, forced }
```

### Constraints

- Only applies to enums with **no associated values**
- Only applies to enums with **no raw values** (e.g. `= 1`, `= "foo"`)
- Only applies when the enum body contains **only `case` declarations** (no methods, computed properties, etc.)
- Only rewrite if all cases fit on a **single line** with the declaration (respect max line length)
- Should be a `SyntaxFormatRule` (transforms syntax)
- Group: `Wrap`

## Tasks

- [x] Create rule file `Sources/SwiftiomaticKit/Syntax/Rules/Wrap/CollapseSimpleEnums.swift`
- [x] Add `Finding.Message` extensions
- [ ] Add configuration entry in `swiftiomatic.json` (user must add — hook blocks agent edits)
- [x] Create test file `Tests/SwiftiomaticTests/Rules/Wrap/CollapseSimpleEnumsTests.swift`
- [x] Write tests covering: basic collapse, associated values (skip), raw values (skip), methods present (skip), too long for one line (skip), single case, access modifiers preserved
- [x] Verify generated pipelines pick up the new rule



## Summary of Changes

Implemented `CollapseSimpleEnums` as a `RewriteSyntaxRule<BasicRuleValue>` in the `wrap` group. The rule merges separate `case` declarations into a single comma-separated `case` on the same line as the enum declaration when:
- All members are case declarations (no methods, properties, etc.)
- No associated values
- No explicit raw value assignments
- No raw-value type inheritance (Int, String, etc.)
- The collapsed form fits within the configured line length

Default: `rewrite: false, lint: .no` (opt-in). 14 tests pass.

User action needed: add `"collapseSimpleEnums": { "lint": "no", "rewrite": false }` to the `wrap` section in `swiftiomatic.json`.
