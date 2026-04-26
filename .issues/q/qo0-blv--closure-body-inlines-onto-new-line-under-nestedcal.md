---
# qo0-blv
title: Closure body inlines onto new line under nestedCallLayout=inline when call args wrap
status: ready
type: bug
priority: normal
created_at: 2026-04-26T03:56:52Z
updated_at: 2026-04-26T03:56:52Z
blocked_by:
    - plm-kyp
sync:
    github:
        issue_number: "442"
        synced_at: "2026-04-26T04:09:22Z"
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
