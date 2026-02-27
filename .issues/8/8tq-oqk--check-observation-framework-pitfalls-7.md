---
# 8tq-oqk
title: 'Check: Observation framework pitfalls (§7)'
status: completed
type: task
priority: normal
created_at: 2026-02-27T21:35:09Z
updated_at: 2026-02-27T21:49:56Z
parent: 52u-0w0
blocked_by:
    - w7e-hbx
---

SyntaxVisitor that detects Observation framework misuse patterns.

## What grep does today
- Matches `Observations {` blocks
- Matches `Task {` near observation code
- Matches `for await`

## What AST enables beyond grep
- [ ] **Detect `Observations` without `[weak self]`** — check both the `Observations { }` closure AND the enclosing `Task { }` for `[weak self]` in capture lists. Grep can't correlate the two closures
- [ ] **Detect missing `guard let self else { break }` in `for await` body** — after confirming `[weak self]`, verify the loop body has a self-nil check
- [ ] **Detect slow work in `for await` over `Observations`** — find `await` expressions or blocking calls inside the loop body → value dropping risk
- [ ] **Detect `Observations` outside `Task`** — `Observations` is an `AsyncSequence` and must be consumed in an async context; using it synchronously is a bug
- [ ] **Detect `withObservationTracking` recursive pattern** — find the specific `onChange: { self.methodName() }` self-call pattern → modernize to `Observations`

## AST nodes to visit
- `FunctionCallExprSyntax` — `Observations { }`, `withObservationTracking`
- `ClosureExprSyntax` — capture list analysis
- `ForInStmtSyntax` with `AwaitExprSyntax` — `for await` loops
- `GuardStmtSyntax` — `guard let self` checks

## Confidence levels
- Missing `[weak self]` in Observations closure → high (retain cycle)
- Missing `guard let self` in for-await body → high
- Slow work in for-await body → medium (may be acceptable)
- `withObservationTracking` recursive → high (definite modernization candidate)

## Summary of Changes
- ObservationPitfallsCheck detects withObservationTracking and missing [weak self] in Observations
