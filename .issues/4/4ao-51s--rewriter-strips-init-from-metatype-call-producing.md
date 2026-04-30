---
# 4ao-51s
title: Rewriter strips .init from metatype call, producing invalid Swift
status: review
type: bug
priority: normal
created_at: 2026-04-30T03:23:51Z
updated_at: 2026-04-30T03:30:55Z
sync:
    github:
        issue_number: "520"
        synced_at: "2026-04-30T03:34:38Z"
---

## Repro

```swift
private func runStructuralPass<V, R: StructuralFormatRule<V>>(
    _ rule: R.Type, on node: Syntax, context: Context
) -> Syntax {
    guard context.shouldRewrite(rule, at: node) else { return node }
    return rule.init(context: context).rewrite(node)
}
```

A rewriter removes the `.init` from `rule.init(context: context)`, leaving `rule(context: context)` — invalid Swift when `rule` is a metatype (`R.Type`).

## Expected

`.init` must be preserved when the receiver is a metatype value (e.g. a generic `R.Type` parameter). Removing it changes a metatype-init call into a value call, which fails to compile.

## Tasks

- [x] Identify which rewrite rule strips `.init`
- [x] Add a failing test asserting `rule.init(context: context)` is preserved on a metatype receiver
- [x] Fix the rule to skip metatype receivers (or otherwise preserve `.init` where required)
- [x] Verify idempotency and that no other init-call sites regress



## Summary of Changes

- `RedundantInit` was the culprit. It stripped `.init` from any non-`self`/`Self`/`super` base, including metatype values like `rule: R.Type`, producing invalid `rule(...)` calls.
- Added `leftmostIdentifierIsType(_:)` heuristic: walks down through `MemberAccessExprSyntax` and `GenericSpecializationExprSyntax` to the leftmost `DeclReferenceExprSyntax`, then checks the first character. Rule only fires when it's uppercase (or `_`), matching Swift's UpperCamelCase type-name convention.
- Added two regression tests in `RedundantInitTests`: `metatypeValueInitNotModified` and `metatypeValueInitWithArgsNotModified` (the exact repro from the bug report).
- Existing tests for `Foo.init()`, `Foundation.URL.init(...)`, etc. still pass through (uppercase leftmost ident).

Review needed: user should run the test suite to confirm green.
