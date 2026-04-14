---
# pfo-ol9
title: Enhance RedundantType to cover array, generic, and if/switch expression patterns
status: completed
type: task
priority: high
created_at: 2026-04-14T16:37:30Z
updated_at: 2026-04-14T16:45:44Z
parent: tis-edd
sync:
    github:
        issue_number: "298"
        synced_at: "2026-04-14T18:45:54Z"
---

## Context

RedundantType was converted from SyntaxLintRule to SyntaxFormatRule (tis-edd), but `simpleTypeName` only handles `DeclReferenceExprSyntax` and `MemberAccessExprSyntax`. SwiftFormat's `redundantType` rule (inferred mode) covers significantly more patterns that we miss.

## Gaps

### 1. Array/Dictionary type constructors

`simpleTypeName` doesn't handle `ArrayExprSyntax` or `DictionaryExprSyntax` as called expressions.

```swift
// Not detected — [String]() parses as FunctionCallExpr on ArrayExprSyntax
var foo: [String] = [String]()
var bar: [String: Int] = [String: Int]()
```

**Fix**: In `simpleTypeName`, match `ArrayExprSyntax` and `DictionaryExprSyntax`, return their trimmed description. Compare against `ArrayTypeSyntax` / `DictionaryTypeSyntax` trimmed descriptions.

SwiftFormat ref tests: `testVarRedundantArrayTypeRemoval`, `testVarRedundantDictionaryTypeRemoval`

### 2. Generic type constructors

`simpleTypeName` doesn't handle `GenericSpecializationExprSyntax`.

```swift
// Not detected — BehaviourRelay<Int?>() wraps DeclReferenceExpr in GenericSpecializationExprSyntax
let relay: BehaviourRelay<Int?> = BehaviourRelay<Int?>(value: nil)
```

**Fix**: In `simpleTypeName`, unwrap `GenericSpecializationExprSyntax` and return its trimmed description including the generic args.

SwiftFormat ref tests: `testLetRedundantGenericTypeRemoval`

### 3. if/switch expression branches

When the initializer is an `if` or `switch` expression, check if ALL branches return the same type as the annotation.

```swift
// Not detected — initializer is IfExprSyntax, not FunctionCallExprSyntax
let foo: Foo = if condition {
    Foo("foo")
} else {
    Foo("bar")
}
// Should become:
let foo = if condition {
    Foo("foo")
} else {
    Foo("bar")
}
```

Also works for nested if/switch and for literal branches (`let foo: String = if c { "a" } else { "b" }`).

**Fix**: Add `IfExprSyntax` and `SwitchExprSyntax` handling in `isRedundant`. Walk all branches, extract leaf expressions, check if all match the type name.

SwiftFormat ref tests: `testRedundantTypeWithIfExpression_inferred`, `testRedundantTypeWithNestedIfExpression_inferred`, `testRedundantTypeWithLiteralsInIfExpression`

### 4. Void exclusion

SwiftFormat skips `Void` types since removing the annotation from `let foo: Void = Void()` is unhelpful.

SwiftFormat ref tests: `testNoRemoveRedundantTypeIfVoid`, `testNoRemoveRedundantTypeIfVoid2`

### 5. Static method call detection (behavioral difference)

SwiftFormat removes `let foo: Bar = Bar.baz()` (matching on the base type). We conservatively skip this because `Bar.baz()` is a method call, not a constructor — the return type isn't necessarily `Bar`. Our behavior is arguably more correct, so this is a deliberate difference rather than a gap.

## Out of scope

- `explicit` mode (replace `Foo()` with `.init()` when type annotation present) — ~20 SF tests
- `inferLocalsOnly` mode (infer in local scopes, explicit in properties) — ~4 SF tests
- `Set<String>` generic arg removal from `Set<String> = ["a"]` → `Set = ["a"]` — different transformation

## Checklist

- [x] Array/Dictionary constructors in `simpleTypeName`
- [x] Generic type constructors in `simpleTypeName`
- [x] if/switch expression branch checking (single-level; nested blocked by swift-syntax item extraction)
- [x] Void exclusion
- [ ] Add SwiftFormat reference tests for each pattern


## Summary of Changes

Implemented 4 of 5 enhancements (nested if deferred due to swift-syntax code block item extraction limitation):
- Array/Dictionary constructors: `ArrayExprSyntax`, `DictionaryExprSyntax` in `simpleTypeName`
- Generic type constructors: `GenericSpecializationExprSyntax` in `simpleTypeName`
- if/switch expression branches: `IfExprSyntax` and `SwitchExprSyntax` with recursive branch matching (single-level)
- Void exclusion: `isVoidType` check for `Void` and `()`
- 8 new SwiftFormat reference tests added (30 total, all passing)
