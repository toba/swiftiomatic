---
# ft4-6aa
title: NestedCallLayout rule
status: draft
type: feature
priority: normal
created_at: 2026-04-24T22:52:08Z
updated_at: 2026-04-24T22:52:08Z
sync:
    github:
        issue_number: "385"
        synced_at: "2026-04-24T22:54:05Z"
---

## Description

A format rule that controls how nested function/initializer call arguments are laid out. Has two modes: **inline** and **wrap**.

### Inline mode

Collapses unnecessarily deep nesting into the most compact form that fits the line width. Tries each form in order, picking the first that fits:

1. **Fully inline** — everything on one line:
   ```swift
   result = ExprSyntax(ForceUnwrapExprSyntax(expression: result, trailingTrivia: trivia))
   ```

2. **Outer inline, inner wrapped** — outer call on one line, inner arguments broken:
   ```swift
   result = ExprSyntax(ForceUnwrapExprSyntax(
       expression: result,
       trailingTrivia: trivia
   ))
   ```

3. **Fully wrapped** — each call on its own line with arguments indented:
   ```swift
   result = ExprSyntax(
       ForceUnwrapExprSyntax(expression: result, trailingTrivia: trivia)
   )
   ```

4. **Fall through to deepest nesting** if nothing else fits:
   ```swift
   result = ExprSyntax(
       ForceUnwrapExprSyntax(
           expression: result,
           trailingTrivia: trivia
       )
   )
   ```

### Wrap mode

Expands any of the compact forms into the fully nested (deepest) form, with each call and its arguments on separate indented lines.

### Input (inline mode)

```swift
result = ExprSyntax(
    ForceUnwrapExprSyntax(
        expression: result,
        trailingTrivia: trivia
    )
)
```

### Expected output (inline mode, assuming it fits)

```swift
result = ExprSyntax(ForceUnwrapExprSyntax(expression: result, trailingTrivia: trivia))
```

## Tasks

- [ ] Create rule file `Sources/SwiftiomaticKit/Syntax/Rules/Wrap/NestedCallLayout.swift`
- [ ] Add configuration for mode (`inline` | `wrap`)
- [ ] Implement inline mode with cascading fit logic
- [ ] Implement wrap mode
- [ ] Add tests
- [ ] Regenerate schema
