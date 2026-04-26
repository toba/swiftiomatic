---
# w4a-lco
title: 'extension where-clause: continuation indent missing on wrapped where'
status: completed
type: bug
priority: normal
created_at: 2026-04-26T18:37:54Z
updated_at: 2026-04-26T18:58:37Z
sync:
    github:
        issue_number: "455"
        synced_at: "2026-04-26T19:03:19Z"
---

The layout engine wraps the `where` clause of an extension declaration to its own line but does not apply continuation indentation.

## Repro

Input (or current output):

```swift
public extension PrimaryKeyedTableDefinition
where PrimaryKey.QueryOutput: IdentifierStringConvertible {
```

## Expected

```swift
public extension PrimaryKeyedTableDefinition
    where PrimaryKey.QueryOutput: IdentifierStringConvertible {
```

The wrapped `where` clause should be indented by one continuation level relative to the `extension` keyword.

## Notes

- Affects `extension` declarations with generic `where` clauses that wrap.
- Likely also affects other decls (struct/class/func) with wrapped `where` clauses — verify.

## Summary of Changes

Changed `.break(.same)` → `.break(.continue)` for the wrapped `where` clause in three layout sites:

- `Sources/SwiftiomaticKit/Layout/Tokens/TokenStream+TypeDeclarations.swift` (type decls)
- `Sources/SwiftiomaticKit/Layout/Tokens/TokenStream+TypeDeclarations.swift` (macro decls)
- `Sources/SwiftiomaticKit/Layout/Tokens/TokenStream+Functions.swift` (function/init/subscript)

Side effect: when the where wraps to a continuation line, the `.reset` break before the opening brace now fires (per the engine's documented behavior), so `{` lands on its own line. This is a deliberate divergence from upstream apple/swift-format (which kept `.break(.same)` here).

Updated 34 layout test fixtures across ClassDeclTests, EnumDeclTests, ExtensionDeclTests, FunctionDeclTests, InitializerDeclTests, MacroDeclTests, StructDeclTests to reflect the new layout. Full test suite: 2962 passed.
