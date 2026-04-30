---
# olu-5s0
title: Guard-return in single-expression closure should rewrite to if/else expression
status: completed
type: bug
priority: normal
created_at: 2026-04-30T17:17:46Z
updated_at: 2026-04-30T20:08:51Z
sync:
    github:
        issue_number: "563"
        synced_at: "2026-04-30T20:09:34Z"
---

When the rule that replaces early returns with if/else is active, the following pattern should be reformatted.

## Before

```swift
attributes.contains { element in
    guard let attr = element.as(AttributeSyntax.self),
          let name = attr.attributeName.as(IdentifierTypeSyntax.self) else { return false }
    return name.name.text == "objc"
}
```

## After

```swift
attributes.contains { element in
    if let attr = element.as(AttributeSyntax.self),
       let name = attr.attributeName.as(IdentifierTypeSyntax.self)
    {
        name.name.text == "objc"
    } else {
        false
    }
}
```

## Notes

- Closure body has the shape: `guard <conditions> else { return X }` followed by `return Y`.
- Rewrite to an `if <conditions> { Y } else { X }` expression — implicit-return style, no `return` keyword on either branch since the closure is single-expression.
- Pattern shows up frequently across the codebase; common with `as(...)` casts inside `contains/filter/first(where:)`.
- Should compose with the existing early-return → if/else rule; verify it triggers when the surrounding closure is the only statement context.



## Summary of Changes

Extended `PreferIfElseChain` to handle the guard-prefix variant: `guard <conds> else { return X }; return Y` rewrites to `if <conds> { Y } else { X }` in implicit-return positions (closure body, single-expression function/accessor body, top-level).

- **`Sources/SwiftiomaticKit/Rules/Conditions/PreferIfElseChain.swift`**: added `tryBuildGuardChain(items:)` and `extractGuardStatement(from:)`. Triggered from `transform` only when the item list is exactly two statements (guard + trailing return), so intermediate code that depends on guard-bound names is never silently moved. Reuses the existing `.useIfElseChain` finding message; anchors on the guard keyword.
- **`Tests/SwiftiomaticTests/Rules/PreferIfElseChainTests.swift`**: 5 new tests — closure body (positive), function body (positive), intermediate-statement (negative), multi-statement guard else (negative), inside switch case (negative).
- Verified no oscillation with `PreferEarlyExits`: the rewritten else-body is a bare expression (no early exit), so `PreferEarlyExits` won't pick it back up.
- Full suite: 3035 passed.
