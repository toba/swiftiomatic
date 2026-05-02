---
# 7yj-tqg
title: splitMultipleDeclsPerLine false positive on enum case with raw value
status: completed
type: bug
priority: normal
created_at: 2026-05-02T16:19:03Z
updated_at: 2026-05-02T16:24:44Z
sync:
    github:
        issue_number: "629"
        synced_at: "2026-05-02T17:32:31Z"
---

## Problem

`splitMultipleDeclsPerLine` incorrectly flags enum cases that combine bare cases with a case that has an explicit raw value, even though they are on a single `case` declaration line (which the rule normally allows).

## Repro

```swift
enum FontWeight: String, XMLIdentifiable {
    static let xmlName = "font-weight"
    case normal, bold, light          // OK — no finding
}

enum FontVariant: String, XMLIdentifiable {
    static let xmlName = "font-variant"
    case normal, smallCaps = "small-caps"   // ⚠️ flagged: move 'smallCaps' to its own 'case' decl
}
```

The rule allows multiple cases on one line, but seems to get confused when one of the elements has a custom raw value, and emits a finding for that element only.

## Expected

No finding — multiple comma-separated cases on a single `case` declaration are permitted by this rule, regardless of whether one has a raw value assignment.

## Likely cause

The rule likely treats a `CaseElement` with a `rawValue` initializer as if it were a separate declaration, instead of recognizing it as still part of the same `EnumCaseDecl`.



## Summary of Changes

Relaxed `SplitMultipleDeclsPerLine` so that enum cases with raw values are no longer split off onto their own `case` declaration. The rule now only splits cases that have *associated values* (parameter clauses).

Rationale: a raw value is a single literal per element — a line like `case normal, smallCaps = "small-caps"` reads cleanly and doesn't carry the same readability concerns as associated-value cases.

### Files

- `Sources/SwiftiomaticKit/Rules/Declarations/SplitMultipleDeclsPerLine.swift` — dropped the `element.rawValue != nil` clause from `willEnter(EnumDeclSyntax:)` and from the transform; updated the doc comment.
- `Tests/SwiftiomaticTests/Rules/SplitMultipleDeclsPerLineTests.swift` — adjusted `invalidCasesOnLine` to expect `leftParen, rightParen = ")", leftBrace, rightBrace = "}"` to remain on one line; replaced `elementOrderIsPreserved` with `rawValueCasesArePermittedOnSameLine` which asserts no findings on the original repro and on `case a = 0, b, c, d`; reworked `commentsAreNotRepeated` to use associated values instead of raw values.

### Verification

- Filtered: `SplitMultipleDeclsPerLineTests` — 11 passed.
- Full suite — 3192 passed, 0 failed.
