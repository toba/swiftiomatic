---
# jq4-b9r
title: 'Check: Performance anti-patterns (§5)'
status: completed
type: task
priority: normal
created_at: 2026-02-27T21:34:30Z
updated_at: 2026-02-27T21:49:56Z
parent: 52u-0w0
blocked_by:
    - w7e-hbx
sync:
    github:
        issue_number: "94"
        synced_at: "2026-03-01T01:01:52Z"
---

SyntaxVisitor that detects performance anti-patterns.

## What grep does today
- Matches `.dropFirst()`, `.flatMap`/`.compactMap` chains, `Date()`
- Matches `Observations {` without `[weak self]`
- Matches `.withLock`, `.remove(at:)`/`.insert(`/`.append(` (mutation during iteration)
- Matches `@TaskLocal`
- Counts `context:` parameter threading (files with 3+)

## What AST enables beyond grep
- [ ] **Detect `.dropFirst()` inside loops** — grep matches all `.dropFirst()` but can't verify it's inside a `for`/`while`. AST walks the parent chain to confirm loop context
- [ ] **Detect mutation during iteration** — find `for item in collection` where `collection` is modified inside the loop body (`.remove(at:)`, `.insert`, `.append`). Grep can't correlate the collection variable
- [ ] **Detect `withLock` containing `await`** — walk the closure body of `.withLock { }` for any `AwaitExprSyntax` → deadlock/performance bug. Grep multiline is unreliable for this
- [ ] **Detect missing `[weak self]` in `Observations` closure** — check `ClosureExprSyntax` capture list for `weak self`. Also check the surrounding `Task {` closure
- [ ] **Detect `for await` over `Observations` with slow work** — find `await` expressions inside `for await` loop bodies iterating Observations (drops intermediate values)
- [ ] **Find `Date()` used for elapsed timing** — detect `Date()` ... `Date().timeIntervalSince(start)` pattern → suggest `ContinuousClock`
- [ ] **Find `public func` with generic params lacking `@inlinable`** — in library targets, generic functions without `@inlinable` pay protocol witness overhead
- [ ] **Detect `[]` / `[x]` passed to `some Collection`/`some Sequence` params** — heap allocation for 0-1 element arrays. AST can check the parameter type of the called function
- [ ] **Find `context:` parameter threading** — count functions taking `context:` per file, flag high-count files as TaskLocal candidates. AST is more precise than grep (excludes comments, default args)

## AST nodes to visit
- `ForStmtSyntax` — check body for mutations on the iterated collection
- `FunctionCallExprSyntax` — `.dropFirst()`, `.withLock`, `Date()`, `.remove(at:)`
- `AwaitExprSyntax` — presence inside `.withLock` closure
- `ClosureExprSyntax` — capture lists for `[weak self]`
- `ForInStmtSyntax` with `AwaitExprSyntax` in iterator — `for await` loops
- `ArrayExprSyntax` with 0-1 elements — check call site parameter type

## Confidence levels
- `.dropFirst()` in loop → high
- Mutation during iteration → high (correctness bug)
- `await` inside `withLock` → high (deadlock risk)
- Missing `[weak self]` in Observations → high (retain cycle)
- `Date()` for timing → medium
- `[]`/`[x]` to generic param → low (micro-optimization)

## Summary of Changes
- PerformanceAntiPatternsCheck detects Date() benchmarking, mutation during iteration, empty/single-element array literals
