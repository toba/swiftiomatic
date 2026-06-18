---
# bhi-jt9
title: Closure body stays inline while closing } wraps alone (single-statement body, elective break)
status: deferred
type: bug
priority: normal
created_at: 2026-06-18T02:25:05Z
updated_at: 2026-06-18T02:25:05Z
blocked_by:
    - qo0-blv
sync:
    github:
        issue_number: "733"
        synced_at: "2026-06-18T02:40:47Z"
---

## Problem

A single-statement closure *with a signature* whose body fits the line by a hair, but whose trailing `}` overflows, breaks raggedly: the body stays on the `in` line and only the closing brace drops to its own line.

### Input
```swift
let isExpanded = Binding<Bool>(
    get: { expanded.contains(node.id) },
    set: { value in if value { expanded.insert(node.id) } else { expanded.remove(node.id) } }
)
```

### Output (current — wrong)
```swift
    set: { value in if value { expanded.insert(node.id) } else { expanded.remove(node.id) }
    }
```

### Desired
```swift
    set: { value in
        if value { expanded.insert(node.id) } else { expanded.remove(node.id) }
    },
```
i.e. when the closing brace must wrap, the body should wrap after `in` too (all-or-none).

## Root cause

`Sources/SwiftiomaticKit/Layout/Tokens/TokenStream+Closures.swift` `visitClosureExpr`: for a closure with a signature, the block-open break is emitted *after* `{` (idx ~103 in the token dump) and the body break after `in` is `.break(.same, newlines: .elective)` for single-statement bodies. The body chunk fits the line (ends at col 99/100) so the after-`in` break does not fire, but the trailing `}`'s `close(mustBreak:true)` break fires via the `!canFit()` path in `LayoutCoordinator.emitToken`, pushing only `}` down.

This token construction *and* the printer's `close(mustBreak:)` logic are byte-faithful to upstream apple/swift-format, so upstream produces the same ragged output at this fit boundary. Fixing it is a deliberate divergence.

## Why deferred

Same family as **qo0-blv** (closure body inlines onto new line under nestedCallLayout=inline) and **fjv-y9j** (if-stmt: keep inline body when conditions wrap). The deferral notes on both record that making the body break all-or-none (`.continue`/`.same`/`.contextual`, or wrapping in an inconsistent group) regresses existing ClosureExprTests/IfStmtTests, because the top-level `.consistent` group force-fires those breaks. Needs a unifying pretty-printer fix across closures/if/guard, not a token tweak.

## Quick-remind anchor

A pointer comment lives in `visitClosureExpr` (TokenStream+Closures.swift) referencing this issue (yhq-… / this id) so a future agent can immediately tell the user this is a known deferred limitation rather than re-investigating.

## Tasks
- [ ] Add failing test reproducing the `{ value in … }` + lone-`}` case
- [ ] Find a unifying all-or-none body-break approach that doesn't regress ClosureExprTests/IfStmtTests
- [ ] Reconcile with qo0-blv (opposite-direction desire) and fjv-y9j

## Deferral Notes

Deferred pending a unified solution to the single-statement-body elective-break family (qo0-blv, fjv-y9j, 09z-px0). Every isolated token-level fix attempted on the siblings regressed existing layout tests; this needs pretty-printer-level work on consistent-group force-breaking. Not safe to attempt in isolation.
