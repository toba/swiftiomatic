---
# v3j-dgc
title: collapseSimpleEnums doesn't collapse CodingKeys enum in Indent.swift
status: completed
type: bug
priority: normal
created_at: 2026-04-25T19:13:23Z
updated_at: 2026-04-25T19:26:49Z
sync:
    github:
        issue_number: "412"
        synced_at: "2026-04-25T19:53:36Z"
---

## Repro

`Sources/SwiftiomaticKit/Layout/Indent.swift` lines 24-27:

```swift
private enum CodingKeys: CodingKey {
    case tabs
    case spaces
}
```

This should be collapsed by `collapseSimpleEnums` to a single-line form, but isn't.

## Expected

Enum collapses to a compact form (e.g. `private enum CodingKeys: CodingKey { case tabs, spaces }` or similar per the rule's contract).

## Actual

Multi-line form is left untouched after running `sm format`.

## Investigation TODO

- [x] Confirm rule is enabled by default / in test config
- [x] Determine whether the conformance clause (`: CodingKey`) trips the rule's gating predicate
- [x] Add a regression test using this exact snippet
- [x] Fix the rule so this case collapses
- [x] Verify on `Indent.swift` after fix (covered by regression test — outer enum has methods + nested `CodingKeys: CodingKey`)


## Summary of Changes

**Root cause:** `CollapseSimpleEnums.visit(_ node: EnumDeclSyntax)` returned `DeclSyntax(node)` unchanged when the outer enum wasn't collapsible, without ever calling `super.visit(node)`. SwiftSyntax's `SyntaxRewriter` only recurses into a node's children when the override calls `super.visit` — so a nested enum like `CodingKeys` inside an outer enum that has methods (e.g. `Indent`) was never visited.

**Fix** (`Sources/SwiftiomaticKit/Rules/Wrap/CollapseSimpleEnums.swift`): call `super.visit(node)` first to recurse into children, then operate on the recursed node. Nested enums now collapse independently of the outer enum's collapsibility.

**Regression test** (`Tests/SwiftiomaticTests/Rules/Wrap/CollapseSimpleEnumsTests.swift`): `collapsesNestedEnumInsideNonCollapsibleEnum` reproduces the `Indent.swift` shape — outer enum with cases, methods, and a nested `private enum CodingKeys: CodingKey` — and asserts the inner enum collapses while the outer is left untouched.

All 15 `CollapseSimpleEnumsTests` pass.
