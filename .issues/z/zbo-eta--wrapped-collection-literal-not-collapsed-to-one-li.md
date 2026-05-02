---
# zbo-eta
title: Wrapped collection literal not collapsed to one line when it fits
status: completed
type: bug
priority: normal
created_at: 2026-05-01T23:16:54Z
updated_at: 2026-05-01T23:48:21Z
sync:
    github:
        issue_number: "618"
        synced_at: "2026-05-02T00:08:55Z"
---

When the inline-block style is in effect (`LayoutSingleLineBodies.mode = .inline`), wrapped statement bodies (`if`/`guard`/`while`/`for`) collapse to one line when they fit. Wrapped collection literals do not — they stay wrapped even when the joined form is comfortably under the print width.

## Reproduction

Input:

```swift
[
    "id",
    "type",
    "within_id",
    "position",
    "name",
    "value",
    "value_type",
]
```

Expected output (joined fits in ~70 chars):

```swift
["id", "type", "within_id", "position", "name", "value", "value_type"]
```

Actual: array stays wrapped.

## Background

- `LayoutSingleLineBodies` (`Sources/SwiftiomaticKit/Rules/Wrap/LayoutSingleLineBodies.swift`) only dispatches on statement-body nodes (`IfExprSyntax`, `GuardStmtSyntax`, `FunctionDeclSyntax`, `InitializerDeclSyntax`, `SubscriptDeclSyntax`, `ForStmtSyntax`, `WhileStmtSyntax`, `RepeatStmtSyntax`, `PatternBindingSyntax`, `AccessorDeclSyntax`). It never touches `ArrayExprSyntax` / `DictionaryExprSyntax`.
- Collection-literal layout lives in `Sources/SwiftiomaticKit/Layout/Tokens/TokenStream+Collections.swift:76-98` (array) and `:102-130` (dictionary). It emits `.break(.open, size: 0)` and `.break(.close, size: 0)` around the brackets and `.break(.same)` between elements — these are *elastic* breaks, so in principle the pretty printer should collapse to one line when the total length fits.
- Trailing-comma normalization (added when multi-line, removed when single-line) is already handled via `Token.commaDelimitedRegionEnd(isCollection:hasTrailingComma:isSingleElement:)` at `Sources/SwiftiomaticKit/Layout/LayoutCoordinator.swift:560`. So if the printer correctly chose "fits as one line", the trailing comma would be stripped automatically.
- Sibling closed issue `wo1-tu8` ("Single-element array literal should always stay inline") fixed the 1-element case. This is the multi-element variant of the same family — that fix did not generalize.
- Length-accumulation for the trailing comma at `LayoutCoordinator.swift:742-755` adds 1 to `total` for the comma whether the array ends up single- or multi-line; this can push borderline arrays over `maxLineLength` and force a break that never relaxes.

## Hypothesis

Likely culprits, ranked:

1. The `.open`/`.close` group that `visitArrayElementList` wraps around each element extends each break's chunk past the next inter-element break, so the printer measures the chunk as too long to fit and fires a break that never relaxes. (See `CLAUDE.md` "Layout & Break Precedence" — `.open` placement vs break chunk bounding.)
2. The trailing-comma length contribution at `LayoutCoordinator.swift:750` is wrong for the "would collapse" branch.
3. Original-source line breaks may be promoted to hard breaks somewhere upstream (check whether array element layout ever inspects source line positions).

## Tasks

- [x] Failing test added in `Tests/SwiftiomaticTests/Rules/Wrap/LayoutSingleLineBodiesTests.swift` under `SingleLineBodiesInlineTests`
- [x] Determined the layout is correct; the issue is that `RespectExistingLineBreaks` preserves source newlines as discretionary breaks, forcing multi-line layout
- [x] Confirmed via syntax-tree inspection that source newlines on element leading trivia drive the multi-line outcome
- [x] Fix applied at the rule layer instead — extended `LayoutSingleLineBodies` to handle `ArrayExprSyntax` / `DictionaryExprSyntax` in `inline` mode
- [x] Trailing comma stripped explicitly in the rewrite (last element's `trailingComma` set to `nil`)
- [x] Filtered suite passes (34/34 SingleLineBodiesInlineTests); full suite has only 2 unrelated failures from concurrent-agent work in `IfStmtTests` / `WrapTernaryBranchesTests`

## Files

- `Sources/SwiftiomaticKit/Layout/Tokens/TokenStream+Collections.swift` (lines 76-130)
- `Sources/SwiftiomaticKit/Layout/Tokens/TokenStream+Breaks.swift` (`markCommaDelimitedRegion`, lines 202-224)
- `Sources/SwiftiomaticKit/Layout/LayoutCoordinator.swift` (lines 560, 742-755 — comma-delimited region length and emit)
- `Sources/SwiftiomaticKit/Rules/Wrap/LayoutSingleLineBodies.swift` (reference for the inline-mode rule the user is invoking)



## Summary of Changes

The layout layer was actually correct — a wrapped array's `.break(.same)` and `.break(.open/.close, size: 0)` are elastic and collapse when the content fits. The reason wrapped arrays stayed wrapped was `RespectExistingLineBreaks` preserving the source newlines on each element's leading trivia as *discretionary* newlines, which forces multi-line layout regardless of fit.

The right scope for the fix is the `LayoutSingleLineBodies` rule (which the user calls the "inline block rule"): in `.inline` mode, opportunistically strip the leading-newline trivia from each element of an `ArrayExprSyntax` / `DictionaryExprSyntax` and drop the last trailing comma when the joined form fits the print width. The pretty printer then naturally collapses the literal to a single line.

### Files modified

- `Sources/SwiftiomaticKit/Rules/Wrap/LayoutSingleLineBodies.swift` — added `transform(_ ArrayExprSyntax …)` / `transform(_ DictionaryExprSyntax …)` plus `inlineArrayLiteral` / `inlineDictionaryLiteral` helpers gated on `.inline` mode. Bails on empty literals, already-inline literals, presence of comments inside the literal, and joined-form-too-long cases. Also tidied stale "compact-pipeline" doc references that no longer apply.
- `Sources/SwiftiomaticKit/Syntax/Rewriter/RewritePipeline.swift` — added `visit(_ node: ArrayExprSyntax)` and `visit(_ node: DictionaryExprSyntax)` that dispatch the new transforms via `apply(LayoutSingleLineBodies.self, …)`.
- `Tests/SwiftiomaticTests/Rules/Wrap/LayoutSingleLineBodiesTests.swift` — added `wrappedArrayLiteralInlines`, `wrappedArrayLiteralStaysWrappedWhenItDoesntFit`, `wrappedDictionaryLiteralInlines`, `alreadyInlineArrayUnchanged`, `emptyArrayUnchanged` under the existing `SingleLineBodiesInlineTests` suite.

All five new tests pass; the existing 29 inline tests still pass.
