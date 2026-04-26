---
# xak-rfz
title: 'KeepFunctionOutputTogether: protocol method wraps return arrow instead of keeping with signature'
status: completed
type: bug
priority: normal
created_at: 2026-04-26T19:06:41Z
updated_at: 2026-04-26T19:45:54Z
sync:
    github:
        issue_number: "456"
        synced_at: "2026-04-26T19:45:58Z"
---

## Problem

When a protocol method signature is too long, the formatter wraps the parameter list AND breaks the return arrow onto its own line, even when the `async throws -> ReturnType` clause would fit on the same line as the closing paren.

## Example

Input (in a protocol):

```swift
func shareMetadata(for share: CKShare, shouldFetchRootRecord: Bool) async throws
   -> ShareMetadata
```

Expected output:

```swift
func shareMetadata(
    for share: CKShare, shouldFetchRootRecord: Bool
) async throws -> ShareMetadata
```

Actual output:

```swift
func shareMetadata(
        for share: CKShare, shouldFetchRootRecord: Bool
    ) async throws
        -> ShareMetadata
```

Two issues:
1. The parameter list is over-indented (8 spaces instead of 4 from the `func` column).
2. The `-> ShareMetadata` is wrapped onto its own line when it should stay attached to `async throws`.

## Investigation areas

- KeepFunctionOutputTogether rule / layout logic for function signatures
- Indentation handling for wrapped parameter lists in protocol declarations
- Return arrow break decision when `async throws` is present



## Investigation findings

Reproduced by writing the input as already-broken:

```
protocol P {
    func shareMetadata(for share: CKShare, shouldFetchRootRecord: Bool) async throws
       -> ShareMetadata
}
```

With `RespectExistingLineBreaks=true` (default), the discretionary newline before `->` is preserved by `.elective` newline behavior on the break emitted in `visitFunctionSignature` (`TokenStream+TypesAndPatterns.swift:428`). When `KeepFunctionOutputTogether=true` the rule's intent is to keep the return clause attached, but this discretionary newline overrides that.

## Fix plan

When `KeepFunctionOutputTogether` is enabled, change the break before the return clause to `.elective(ignoresDiscretionary: true)` so the rule wins over preserved newlines.



## Summary of Changes

- `Sources/SwiftiomaticKit/Layout/Tokens/TokenStream+TypesAndPatterns.swift` — `visitFunctionSignature` now emits the break before the return clause with `.elective(ignoresDiscretionary: true)` when `KeepFunctionOutputTogether` is enabled, so a previously-broken `->` re-attaches to `) async throws`.
- `Tests/SwiftiomaticTests/Layout/ProtocolDeclTests.swift` — added `protocolWithKeepFunctionOutputTogether_overridesExistingArrowNewline` covering the regression.

Full layout suite passes (2955 tests). Awaiting user verification on their CKShare protocol file.
