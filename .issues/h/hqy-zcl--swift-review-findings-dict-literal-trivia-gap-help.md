---
# hqy-zcl
title: 'Swift review findings: dict literal trivia gap, helper consolidation, ternary perf'
status: completed
type: task
priority: normal
created_at: 2026-05-01T23:58:11Z
updated_at: 2026-05-02T00:06:51Z
sync:
    github:
        issue_number: "617"
        synced_at: "2026-05-02T00:08:55Z"
---

Findings from /swift review of issues completed 2026-05-01 (rua-efw, zbo-eta, 71r-8n7, t8p-jfj, slg-5gh, 83k-hv9).

## Medium

### Dictionary literal collapse misses key.trailingTrivia and value.leadingTrivia
`Sources/SwiftiomaticKit/Rules/Wrap/LayoutSingleLineBodies.swift:867` (`inlineDictionaryLiteral`)

The array variant (`inlineArrayLiteral`, ~:795) clears both `expression.leadingTrivia` and `expression.trailingTrivia` on each element. The dictionary variant clears only `key.leadingTrivia` and `value.trailingTrivia` — missing `key.trailingTrivia` (whitespace before `:`) and `value.leadingTrivia` (whitespace/newlines after `:`).

A source like:
```swift
[
  "a"
    : 1,
]
```
may collapse with a stray newline/indent surrounding the colon. Add a failing test that exercises odd whitespace around the colon, then mirror the array variant's full reset.

### Consolidate `inlineArrayLiteral` and `inlineDictionaryLiteral`
`Sources/SwiftiomaticKit/Rules/Wrap/LayoutSingleLineBodies.swift:795` and `:843`

~50 lines of near-duplicated logic: multiline detection, comment-rejection, joined-length check, diagnostic emission, trivia clearing. Differ only in element rendering and the keypath to the element list. Extract a shared helper that takes a render closure and a left/right-bracket pair.

## Low

### `WrapTernaryBranches.singleLineLength` allocates two intermediate sequences
`Sources/SwiftiomaticKit/Rules/Wrap/WrapTernaryBranches.swift:117`

`trimmedDescription.split(...).joined(...).count` allocates per ternary on a hot path. A single scalar-pass counter (skip-runs of whitespace) would avoid the allocations.

### `WrapTernaryBranches.sourceLineLength` returns UTF-8 bytes but compares to character-based LineLength
`Sources/SwiftiomaticKit/Rules/Wrap/WrapTernaryBranches.swift:148`

The inline comment notes ASCII-heavy source makes UTF-8 a safe upper bound. For source with multi-byte identifiers/comments this can over-wrap. Consider `String.unicodeScalars.count` over the line slice, or measure column from `SourceLocationConverter` directly.

### `DropRedundantSelf.knownDynamicMemberLookupTypes` is a hardcoded allow-list
`Sources/SwiftiomaticKit/Rules/Redundancies/DropRedundantSelf.swift:45`

User-defined `@dynamicMemberLookup` types in other modules are not detected. Source-local declarations and the listed stdlib/SwiftUI types are handled; cross-module conformances silently strip required `self.`. Document as a known limitation in the rule docstring, or consider a config key for additional type names.

## Tasks

- [x] Add test reproducing dictionary trivia gap
- [x] Mirror array variant's trivia reset in dict helper
- [x] Extract shared `inlineCollectionLiteral` helper
- [x] (optional) Replace `split/joined/count` in `singleLineLength` with scalar pass
- [x] (optional) Document `DropRedundantSelf` cross-module limitation in rule docstring


## Summary of Changes

- Added `dictionaryLiteralWithWhitespaceAroundColonInlines` test reproducing the trivia gap (whitespace/newlines around `:`).
- Fixed `inlineDictionaryLiteral` to clear `key.trailingTrivia`, `colon.leadingTrivia`, `colon.trailingTrivia` (reset to single space), and `value.leadingTrivia` — mirroring the array variant's full reset.
- Extracted shared `shouldInlineCollection<E>` helper covering the multiline check, comment rejection, joined-length check, and diagnostic emission. Both `inlineArrayLiteral` and `inlineDictionaryLiteral` now call it; element-specific trivia mutation stays in each variant.
- Replaced `WrapTernaryBranches.singleLineLength`'s `split(...).joined(...).count` with a single-pass `Character` scan that collapses whitespace runs in place — no intermediate allocations.
- Documented `DropRedundantSelf`'s `@dynamicMemberLookup` cross-module limitation in the rule docstring.

All 3174 tests pass.
