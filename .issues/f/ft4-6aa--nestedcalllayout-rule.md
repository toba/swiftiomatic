---
# ft4-6aa
title: NestedCallLayout rule
status: completed
type: feature
priority: normal
created_at: 2026-04-24T22:52:08Z
updated_at: 2026-04-25T02:24:43Z
sync:
    github:
        issue_number: "385"
        synced_at: "2026-04-25T02:39:17Z"
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

- [x] Create rule file `Sources/SwiftiomaticKit/Syntax/Rules/Wrap/NestedCallLayout.swift`
- [x] Add configuration for mode (`inline` | `wrap`)
- [x] Implement inline mode with cascading fit logic
- [x] Implement wrap mode
- [x] Add tests (14 tests: 8 inline, 6 wrap)
- [x] Regenerate schema


## Summary of Changes

Implemented the `NestedCallLayout` rule with two modes:

- **Inline mode**: cascading fit strategy (fully inline → outer inline/inner wrapped → fully wrapped/inner inline → fully nested)
- **Wrap mode**: expands any compact form to fully nested

Key implementation details:
- `columnOffset()` helper walks backward through tokens (avoids SourceLocationConverter discrepancies between direct and pipeline contexts)
- `lineIndentation()` helper finds the indent at the start of the containing line
- `inlineArgText()` joins arguments with `, ` to avoid preserving internal newlines from `trimmedDescription`
- Rule defaults to off (`rewrite: false, lint: .no`) — opt-in via `wrap.nestedCallLayout` config

Files:
- `Sources/SwiftiomaticKit/Syntax/Rules/Wrap/NestedCallLayout.swift` — rule + configuration
- `Tests/SwiftiomaticTests/Rules/Wrap/NestedCallLayoutTests.swift` — 14 tests
- `Tests/SwiftiomaticTestSupport/Configuration+Testing.swift` — test config registration
- `schema.json` — regenerated
