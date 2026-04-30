---
# olu-5s0
title: Guard-return in single-expression closure should rewrite to if/else expression
status: ready
type: bug
priority: normal
created_at: 2026-04-30T17:17:46Z
updated_at: 2026-04-30T17:17:46Z
sync:
    github:
        issue_number: "563"
        synced_at: "2026-04-30T18:07:55Z"
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
