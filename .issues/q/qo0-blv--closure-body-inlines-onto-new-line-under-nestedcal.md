---
# qo0-blv
title: Closure body inlines onto new line under nestedCallLayout=inline when call args wrap
status: draft
type: bug
priority: normal
created_at: 2026-04-26T03:56:52Z
updated_at: 2026-04-26T17:30:21Z
blocked_by:
    - plm-kyp
sync:
    github:
        issue_number: "442"
        synced_at: "2026-04-26T18:08:47Z"
---

## Problem

Follow-up to plm-kyp. With `nestedCallLayout: "inline"` (default), a single-statement closure body whose body is a function call that wraps gets pushed onto its own line — defeating the inline layout.

### Input (preferred)
```swift
let count = try await sqlite.read { try Int.fetchOne(
    $0,
    sql: "...long string...",
    arguments: StatementArguments(ids)
) ?? 0 }
```

### Output (current, after plm-kyp Fix 1)
```swift
let count = try await sqlite.read {
  try Int.fetchOne(
    $0,
    sql: "...long string...",
    arguments: StatementArguments(ids)
  ) ?? 0
}
```

## Root cause

`Sources/SwiftiomaticKit/Layout/Tokens/TokenStream+Closures.swift` (~line 16) wraps single-statement closure bodies with a `.elective` newline behavior. Once the inner call wraps internally, the closure body becomes multi-line and the open break after `{` fires (length-of-group > line limit), pushing the body's first token onto a new line.

The savings-threshold heuristic added in plm-kyp doesn't help here: the open break's group length is the entire body, and the savings from wrapping ARE big (~30 cols). The heuristic correctly fires.

What's needed: for a single-statement closure body under inline mode, the post-`{` break should fire only when the FIRST CHUNK (up to the next inner break) doesn't fit, not when the entire body group doesn't fit.

## Approach (sketch)

Either:
1. Change `visitClosureExpr` to use `.same` (or `.continue`) kind for single-statement closure bodies under inline mode — keeps brace and body's leading expression together when the leading expression fits.
2. Special-case the open-break length calculation for single-statement closures so it considers only the first chunk.

Risk: may regress existing closure-body formatting tests. Needs careful test coverage.

## Tasks

- [ ] Add failing test reproducing the user's exact input
- [ ] Implement closure-body inline preservation under `nestedCallLayout: inline`
- [ ] Verify no regressions in ClosureExprTests and related layout tests
- [ ] Check interaction with multi-statement closures and signatures

## Investigation — 2026-04-26

Three approaches attempted; none viable without significant pretty-printer changes.

### Approach 1: Replace `arrangeBracesAndContents` with `.break(.continue)` after `{` and before `}`

`Sources/SwiftiomaticKit/Layout/Tokens/TokenStream+Closures.swift` `visitClosureExpr`. The intent was: a `.break(.continue)` break's length is the distance to the next break (first chunk only), so the firing decision considers only the leading expression instead of the whole body.

**Why it fails:** `TryExpr`'s `before(tryKeyword, .open)` (`Sources/SwiftiomaticKit/Layout/Tokens/TokenStream+TypesAndPatterns.swift:101`) inserts an `.open` consistency marker between our `.break(.continue)` and the body's first inner break. In `LayoutCoordinator.prettyPrint()`'s length computation, an intervening `.open` blocks the natural break-finalization handshake — the `.break(.continue)`'s length grows to span the entire body, identical to the original `.break(.open)` behavior. Token dump confirmed: closure-body break at idx 61 had length 573 (whole body), not the expected 4 (`try`).

### Approach 2: Defer registration to `visitPostClosureExpr`

Idea: register the break in `visitPost` so it is emitted *inside* the child-registered `.open` markers.

**Why it fails:** `TokenStream`'s `walk(node)` emits leaf tokens during traversal — by the time `visitPostClosureExpr` fires, the `try` leaf token has already been emitted (with whatever was in `beforeMap[try]` at that moment). `visitPost` registrations come too late.

### Approach 3: Extend the plm-kyp savings heuristic to `.open` break kind

Idea: in `LayoutCoordinator.swift:428–445`, also suppress `.open` breaks when wrapping wouldn't bring the line under the limit and savings are minimal.

**Why it doesn't apply:** the savings calculation (`unwrap_end - postwrap_end = currentColumn - indentColumns`) is large here (~30 cols) — the wrap *does* save columns. The user's principle "if savings < threshold" doesn't capture this case. The actual desired semantic is "fire only if the FIRST INNER CHUNK doesn't fit", which requires a different look-ahead in `LayoutCoordinator`.

## What would a real fix look like?

A real fix needs LayoutCoordinator-level support: a new break-firing variant that uses first-inner-chunk length instead of group length. Specifically:

1. Add an annotation (e.g. a new `OpenBreakKind` case or a flag on `NewlineBehavior`) that marks the closure-body break as "first-chunk-fires".
2. In `LayoutCoordinator.emitToken` (around `LayoutCoordinator.swift:217–471`), when this annotation is set on a `.break(.open)`, walk forward in `tokens[]` to find the first nested break (skipping our own consistency `.open`/`.close` pair), measure the bytes between, and use that for `canFit` instead of `length`.
3. Audit existing closure tests for regressions — likely 5–20 test outputs change.

## Recommendation

Defer. The current behavior (body wraps when long) is correct per the standard pretty-printer model; the user's preferred layout requires a specialized first-chunk-fires semantic that doesn't exist in upstream swift-format either. The plm-kyp savings heuristic already addresses the long-string wrap; the closure-body wrap is cosmetically suboptimal but functionally correct.

If we do invest, the fix is contained to LayoutCoordinator + the closure visitor — risk surface is the existing closure layout tests. Expect a multi-hour task with careful test review.
