---
# 9k4-xq4
title: 'rule [flagForEachIDSelfInView] false-positive on ''id: \\.element.id'' (enumerated)'
status: completed
type: bug
priority: normal
created_at: 2026-05-08T02:13:17Z
updated_at: 2026-05-08T02:45:53Z
sync:
    github:
        issue_number: "647"
        synced_at: "2026-05-08T02:54:15Z"
---

## Symptom

```swift
ForEach(Array(tags.enumerated()), id: \.element.id) { index, tag in
    ...
}
```

Diagnostic:
```
App/Sources/Views/Tag/TagPicker.swift:141:43: warning: [flagForEachIDSelfInView] 'id: \.self' is fragile — make the element 'Identifiable' or supply a stable id key path
```

The `id:` key path is `\.element.id` — a stable id reaching through `(offset, element)` tuples. The rule appears to fire on any `ForEach(_, id:)` form that does not use bare `Identifiable` conformance, missing the case where the user has already supplied a stable key path.

## Expected

The rule should only fire when:
- The id argument is literally `\.self`, or
- (optionally) when the receiver is a sequence of mutable value types where `\.self` fragility is the actual concern.

It should not fire on `\.element.id`, `\.id`, or any key path containing `.id`.

## Detection

Match only the literal key-path expression `\.self`. Do not flag any key path containing `.id` or other compound member accesses.

## Repro

Thesis project, `App/Sources/Views/Tag/TagPicker.swift:141`.



## Summary of Changes

Verified the rule already correctly skips compound key paths like `\.element.id` (only fires when the key path has exactly one component and that component is the `self` keyword). Added a regression test `compoundKeyPathNotFlagged` covering the `Array(tags.enumerated())` + `\.element.id` repro.

The original report likely conflated this with the adjacent `*.indices` / `\.self` false-positive (see 8h8-eej), which is fixed in the same commit.

Files:
- `Tests/SwiftiomaticTests/Rules/FlagForEachIDSelfInViewTests.swift` — added regression test
