---
# fjv-y9j
title: 'if-stmt: keep inline body when conditions wrap (deferred from n6q-htv)'
status: draft
type: feature
priority: normal
created_at: 2026-04-26T18:07:08Z
updated_at: 2026-04-26T18:07:08Z
sync:
    github:
        issue_number: "446"
        synced_at: "2026-04-26T18:08:47Z"
---

## Problem

Sibling of n6q-htv (which solved the `guard` case). When an `if` statement has conditions that wrap across multiple lines and the body is a single-statement single-line body, ideally the `{ stmt }` should stay attached to the closing condition when it fits within `LineLength`:

```swift
// current
if foo,
   bar
{ doThing() }

// desired
if foo,
   bar { doThing() }
```

## Why this is harder than the guard case

In `n6q-htv` the guard fix wrapped `else { stmt }` in an outer `.open(.inconsistent)` group with a `.break(.same, ..., .elective(ignoresDiscretionary: true))` so the printer could evaluate the whole inline form's length at the break point. The same approach was attempted for `if` (in `Sources/SwiftiomaticKit/Layout/Tokens/TokenStream+ControlFlow.swift::visitIfExpr`) but it broke 3 existing layout tests:

- `IfStmtTests/optionalBindingConditions`
- `IfStmtTests/multipleIfStmts`
- the new `attachesInlineBodyToWrappedIfConditions`

### Root cause

`Sources/SwiftiomaticKit/Layout/Tokens/TokenStream+MembersAndBlocks.swift::visitCodeBlockItem` (lines 197-215) wraps every top-level if-stmt in an `.open(.consistent)` group spanning **conditions through last `}`**:

```swift
before(ifStmt.conditions.firstToken(...), tokens: .open(.consistent))
after(ifStmt.lastToken(...), tokens: .close)
```

The comment explains the intent: "all of the bodies will have the same breaking behavior" — i.e. an `if X { } else if Y { } else { }` chain wraps consistently across all bodies.

A `.consistent` group force-fires every break inside it when the group doesn't fit OR when `lastBreak` was true at its open. In `LayoutCoordinator.swift:218`:

```swift
var mustBreak = forceBreakStack.last ?? false
```

This is read for **every** break kind. The existing `.reset` break (used today before the body's `{` via `arrangeBracesAndContents`) overrides this in `LayoutCoordinator.swift:366-367`:

```swift
case .reset:
    mustBreak = currentLineIsContinuation
```

So `.reset` ignores the consistent force and only fires when on a continuation line. A `.same` break (what we'd want for elective fit-aware behavior) does **not** override:

```swift
case .same:
    break
```

So under the consistent group, a `.same` break before the body always force-fires, regardless of whether the body would fit.

## Approaches considered

1. **Use `.contextual` instead of `.same`** — also subject to forceBreakStack force.
2. **Wrap body in our own inconsistent group earlier** — our break sits between the consistent open and the inconsistent open, still inside the consistent scope.
3. **Modify visitCodeBlockItem to scope the consistent group to conditions only** — defeats the "consistent body breaking across else-if chains" intent.
4. **Add a new BreakKind that respects canFit but ignores forceBreakStack** — broader printer change; needs design discussion.
5. **AST rewrite via WrapSingleLineBodies** — column-unaware, can't make a correct decision without printer integration.

## Suggested next steps

- Decide whether the "consistent body breaking across an if/else-if chain" guarantee is worth the cost of forcing wrap when the inline body would fit. Two existing tests (`optionalBindingConditions`, `multipleIfStmts`) currently rely on it.
- If yes: introduce a new `.elective`-style break kind that respects `canFit(length)` but is exempt from `forceBreakStack` force-fire. Update `LayoutCoordinator.swift::case .break` accordingly.
- If no (acceptable to relax): scope the `.open(.consistent)` in `visitCodeBlockItem` to conditions only, and rely on a separate mechanism for else-chain consistency.
- Then mirror the guard fix in `visitIfExpr`: wrap `{ stmt }` in `.open(.inconsistent)` with the new break kind before `leftBrace`, and `.close` after `rightBrace`.

## Reference

- Guard fix: `Sources/SwiftiomaticKit/Rules/LineBreaks/BeforeGuardConditions.swift`
- Helper: `CodeBlockSyntax.isInlineSingleStatementBody` in `Sources/SwiftiomaticKit/Extensions/CodeBlockSyntax+Convenience.swift`
- Parent issue: n6q-htv

## Tests to add (deferred)

- `IfStmtTests/attachesInlineBodyToWrappedIfConditions`
- `IfStmtTests/breaksIfBodyWhenInlineExceedsLineLength`
- `IfStmtTests/multiStatementIfBodyAlwaysBreaksBrace`
- Update existing `optionalBindingConditions` and `multipleIfStmts` expectations.
