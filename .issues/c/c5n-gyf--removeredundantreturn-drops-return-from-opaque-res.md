---
# c5n-gyf
title: removeRedundantReturn drops return from opaque-result branches with unbound generics
status: completed
type: bug
priority: high
tags:
    - enhancement
created_at: 2026-05-10T04:57:54Z
updated_at: 2026-05-10T05:05:11Z
sync:
    github:
        issue_number: "689"
        synced_at: "2026-05-10T05:07:26Z"
---

The "drop redundant `return`" transformation is unsound when the function's return type is an opaque-result (`some Protocol<...>`) whose generic parameter is not pinned by the branch expression alone.

## Reproducer (from real-world breakage in thesis)

```swift
public extension QueryExpression where QueryValue: FloatingPoint {
    func round(
        _ precision: (some QueryExpression<Int>)? = Int?.none,
    ) -> some QueryExpression<QueryValue> {
        if let precision {
            return QueryFunction("round", self, precision)
        } else {
            return QueryFunction("round", self)
        }
    }
}
```

After `sm` runs:

```swift
    func round(
        _ precision: (some QueryExpression<Int>)? = Int?.none,
    ) -> some QueryExpression<QueryValue> {
        if let precision {
            QueryFunction("round", self, precision)   // <- return stripped
        } else {
            QueryFunction("round", self)              // <- return stripped
        }
    }
```

`swiftc` rejects with:

> error: generic parameter 'QueryValue' could not be inferred

`QueryFunction` is generic on its own `QueryValue`, and neither branch carries information binding it to the *outer* `QueryValue` from the function signature. With the explicit `return`, the inferrer flows the function's declared return type back through each branch and binds `QueryFunction.QueryValue == QueryValue`. Without `return`, the if/else is parsed as an if-expression and inference can't pin the outer generic from the branch expressions in isolation.

## Other examples in the same file

Same pattern broke 6 functions in `Core/Sources/Storage/Functions/ScalarFunctions.swift` (PF swift-structured-queries vendored): `round`, `ltrim`, `rtrim`, `substr`, `trim`, `unhex`.

Single-branch bodies (e.g. `length`, `abs`, `sign`, `octetLength`) are fine — only the multi-branch if-expression form regresses.

## Suggested fix

Don't apply `removeRedundantReturn` (or whatever the rule is named) when:
- the enclosing function's return type contains `some` (opaque result), AND
- any branch expression is a generic call whose type would be inferred from the contextual return type rather than from its own arguments.

A safer approximation: skip the transform whenever the return type contains `some` or `any` and the body has multiple `return` statements that would collapse to an if-expression. The `return` keyword is cheap; saving it isn't worth breaking opaque-result inference.

## Impact

Build-broke `Core` and cascaded ~973 linker errors across 9 downstream targets in thesis. Caught only because the build was attempted; lint passes clean (the transform produces syntactically valid code).



## Summary of Changes

Skip the multi-branch (`containsExhaustiveReturn`) transform when the enclosing decl's return type contains a `some` or `any` keyword token. The single-return single-expression path is unaffected — the contextual return type still flows directly to a single expression with or without the keyword.

- `Sources/SwiftiomaticKit/Rules/Redundancies/DropRedundantReturn.swift`: added `typeUsesOpaqueOrExistential(_:)` helper; gated the if/switch-expression collapse in `transform(FunctionDeclSyntax)`, `transformAccessorBlock(_:returnType:context:)` (now takes the return type), `transform(SubscriptDeclSyntax)`, and `transform(PatternBindingSyntax)` on it.
- `Tests/SwiftiomaticTests/Rules/OmitReturnsTests.swift`: added `opaqueReturnTypeIfElseNotTransformed` (the thesis `QueryExpression.round` reproducer), `existentialReturnTypeIfElseNotTransformed`, and `opaqueReturnTypeSingleReturnStillTransformed`.

Closures aren't gated — they rarely carry an explicit opaque/existential return clause, and the rule already only fires on closures that the rewriter sees in isolation.

Verified: filtered `OmitReturnsTests` (21/21) and the full suite (3367/3367) pass.
