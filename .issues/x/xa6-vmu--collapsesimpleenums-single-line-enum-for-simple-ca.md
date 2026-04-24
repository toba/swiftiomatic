---
# xa6-vmu
title: 'CollapseSimpleEnums: single-line enum for simple cases'
status: in-progress
type: feature
priority: normal
created_at: 2026-04-24T22:40:51Z
updated_at: 2026-04-24T22:42:58Z
sync:
    github:
        issue_number: "388"
        synced_at: "2026-04-24T22:54:05Z"
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

- [ ] Create rule file `Sources/SwiftiomaticKit/Syntax/Rules/Wrap/CollapseSimpleEnums.swift`
- [ ] Add `Finding.Message` extensions
- [ ] Add configuration entry in `swiftiomatic.json`
- [ ] Create test file `Tests/SwiftiomaticTests/Rules/Wrap/CollapseSimpleEnumsTests.swift`
- [ ] Write tests covering: basic collapse, associated values (skip), raw values (skip), methods present (skip), too long for one line (skip), single case, access modifiers preserved
- [ ] Verify generated pipelines pick up the new rule
