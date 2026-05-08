---
# ke5-6mj
title: Don't wrap Regex generic argument with tuple type when it fits
status: completed
type: bug
priority: normal
created_at: 2026-05-08T06:17:35Z
updated_at: 2026-05-08T06:43:37Z
---

Input:
```
static var pattern: Regex<(
    Substring,
    red: Substring,
    green: Substring,
    blue: Substring,
    opacity: Substring?,
)> { get }
```

Should not be reformatted to:
```
static var pattern:
    Regex<
        (
            Substring,
            red: Substring,
            green: Substring,
            blue: Substring,
            opacity: Substring?,
        )
    >
{ get }
```

The original layout (variable name on one line, generic open and close around the tuple) fits and is idiomatic. The pretty printer is over-wrapping the type by breaking before `Regex<` and forcing the `{ get }` accessor block onto its own line.



## Summary of Changes

Fixed two interacting issues in the pretty printer that combined to over-wrap a Regex generic with a wrapping tuple argument:

1. **`visitGenericArgumentClause`** (`Sources/SwiftiomaticKit/Layout/Tokens/TokenStream+TypesAndPatterns.swift`): When the only generic argument is a type that brings its own paren / brace delimiters (currently: tuple types), suppress the inner break around `<` and `>` and instead emit only group brackets. The inner tuple wraps via its own `(` / `)` mechanism.

2. **`visitPatternBinding`** (`Sources/SwiftiomaticKit/Layout/Tokens/TokenStream+Bindings.swift`): When the type annotation's type is self-wrapping (tuple type, function type, inline-array type, or a single-argument generic whose only argument is itself self-wrapping), emit a plain space after `:` instead of a continuation break. This keeps the type glued to the binding name and lets the type wrap via its own inner delimiter rather than being pushed onto its own line.

Added helper `openingSelfWrappingDelimiter(of:)` to walk into single-arg generics to find the innermost self-wrapping delimiter.

### Tests

- Added `VariableDeclarationTests/genericArgWithWrappingTupleStaysGlued` covering the user-reported `Regex<(...)>` case.
- Updated three existing test expectations whose output is now cleaner with the new behavior:
  - `PatternBindingTests/bindingIncludingTypeAnnotation`
  - `VariableDeclarationTests/basicVariableDecl`
  - `ArrayDeclTests/inlineArrayTypeSugarWhenLineLengthExceeded`

Full suite: 3255 passing, 1 pre-existing unrelated failure (`AssignmentExprTests/assignmentWithChainOfTrailingClosureCalls` — fails on HEAD before any of my changes).
