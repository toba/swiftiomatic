---
# kic-yda
title: 'Where-clause layout: glue ''where'' to decl when requirements span multiple lines'
status: completed
type: feature
priority: normal
created_at: 2026-05-09T02:01:00Z
updated_at: 2026-05-09T02:35:20Z
sync:
    github:
        issue_number: "675"
        synced_at: "2026-05-09T02:38:08Z"
---

## Problem

When a generic where clause forces multi-line wrapping, current layout puts `where` on its own line:

```swift
public extension TableColumnExpression
    where
        Root: FTS5,
        Value.QueryOutput: OptionalExpressible,
        Value.QueryOutput.OptionalType.Wrapped: StringProtocol
{
```

Desired:

```swift
public extension TableColumnExpression where
    Root: FTS5,
    Value.QueryOutput: OptionalExpressible,
    Value.QueryOutput.OptionalType.Wrapped: StringProtocol
{
```

## Three-tier behavior

1. Fits entirely on decl line → keep on one line.
2. `where + reqs` fits on a single subsequent line → break before `where`, keep reqs together (current case 2 — unchanged).
3. `where + reqs` won't fit on a single subsequent line → keep `where` glued to decl line, break each requirement onto its own line.

## Plan

- Pre-compute rendered width of `where <reqs>` from syntax in arrange*Decl helpers.
- If width > availableWidth (continueIndent baseline): use new layout (space before where, must-break inter-req breaks, consistent group).
- Else: keep current tokens.
- Apply to extension, class, struct, enum, protocol, typealias, function, init, subscript, macro.

## Tasks

- [x] Add failing test reproducing the TableColumnExpression case
- [x] Implement width-based branch in arrangeTypeDeclBlock
- [x] Apply same branch in arrangeFunctionLikeDecl and other decl paths
- [x] Update existing test expectations for multi-line where cases (ExtensionDeclTests, ClassDeclTests, StructDeclTests, EnumDeclTests, FunctionDeclTests, InitializerDeclTests, SubscriptDeclTests, MacroDeclTests)
- [x] Run full test suite, confirm no unrelated regressions


## Summary of Changes

- New helper `arrangeGenericWhereClause(_:trailingClose:)` in `TokenStream+Miscellaneous.swift` chooses between two layouts based on the rendered width of `where <requirements>`. When the where-clause text wouldn't fit on a single subsequent line, the helper marks the clause's `SyntaxIdentifier` in a new `multiLineWhereClauses` set on `TokenStreamBase` and bounds the break-before-`where` group to the `where` keyword alone — its tiny chunk almost never fires, keeping `where` glued to the preceding decl token.
- `visitGenericWhereClause` reads the flag and emits the matching `.close` plus a forced `.break(.open, newlines: .soft)` in a single `after()` call (so the `afterMap` reversal preserves their relative order), and switches the requirements list to a `.consistent` group so all inter-requirement breaks fire together.
- Width heuristic uses `requirements.trimmedDescription` length plus `where ` prefix, compared against `maxLineLength - indentWidth`.
- Updated five decl-arrangement call sites (`arrangeMacroDecl`, `arrangeTypeDeclBlock`, subscript, function-like, typealias, associatedtype) to use the new helper.
- Updated existing test expectations across 7 test files. Full suite (3286 tests) passes.
