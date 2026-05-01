---
# 3aq-p4v
title: wrapTernary breaks string interpolation segments
status: completed
type: bug
priority: high
created_at: 2026-05-01T16:57:07Z
updated_at: 2026-05-01T17:03:52Z
sync:
    github:
        issue_number: "602"
        synced_at: "2026-05-01T17:11:52Z"
---

## Bug

When a ternary expression appears inside a string interpolation segment, `wrapTernary` wraps the `?` and `:` onto new lines, which produces invalid Swift syntax — string interpolations must remain on a single logical line within the literal.

## Repro

Input (valid):

```swift
if result.summary.linkerErrors > 0 {
    details.append(
        "\(result.summary.linkerErrors) linker error\(result.summary.linkerErrors == 1 ? "" : "s")",
    )
}
```

After `sm format` (invalid — newlines inside the interpolation):

```swift
if result.summary.linkerErrors > 0 {
    details.append(
        "\(result.summary.linkerErrors) linker error\(result.summary.linkerErrors == 1 
? "" 
: "s")",
    )
}
```

## Expected

Ternaries inside string interpolation segments (`ExpressionSegmentSyntax`) should not be wrapped — the interpolation must stay on one line, or the entire literal needs to be reformatted as a multi-line string.

## Likely fix

In `wrapTernary` (StaticFormatRule), skip when any ancestor is `ExpressionSegmentSyntax` (or check `StringLiteralExprSyntax` with non-multiline delimiter).

## Tasks

- [x] Add failing test reproducing the case above
- [x] Guard `wrapTernary` against ternaries inside string interpolation segments
- [x] Run filtered tests, then full suite



## Summary of Changes

- `Sources/SwiftiomaticKit/Rules/Wrap/WrapTernary.swift`: added `isInsideSingleLineStringInterpolation(parent:)` ancestor-chain check (mirrors `hasAncestorTernary`) and an early return at the top of `transform` when the ternary lives inside a single-line string literal's `\(...)` segment. Multiline `"""..."""` literals are unaffected since newlines are valid there.
- `Tests/SwiftiomaticTests/Rules/Wrap/WrapTernaryTests.swift`: added `ternaryInsideSingleLineStringInterpolationNotWrapped` regression test using the user's repro.
- Filtered: 4/4 pass. Full suite: 3155/3155 pass.
