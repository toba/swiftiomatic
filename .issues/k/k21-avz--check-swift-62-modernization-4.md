---
# k21-avz
title: 'Check: Swift 6.2 modernization (§4)'
status: completed
type: task
priority: normal
created_at: 2026-02-27T21:34:06Z
updated_at: 2026-02-27T21:49:56Z
parent: 52u-0w0
blocked_by:
    - w7e-hbx
sync:
    github:
        issue_number: "73"
        synced_at: "2026-03-01T01:01:43Z"
---

SyntaxVisitor that identifies Swift 6.2 modernization opportunities.

## What grep does today
- Matches `Task.detached` (→ @concurrent)
- Matches `UnsafeRawBufferPointer`, `UnsafeBufferPointer`, `baseAddress!` (→ Span)
- Matches `withUnsafeBytes` / `withUnsafeMutableBytes`
- Matches `weak var` (→ weak let)
- Matches `withObservationTracking` (→ Observations)
- Flags `didSet`/`willSet`, `static var` as opportunities

## What AST enables beyond grep
- [ ] **Detect `weak var` never reassigned** — walk `init` body to find assignment, then check no other assignment exists in the type → `weak let` candidate. Grep cannot distinguish reassigned vs never-reassigned
- [ ] **Detect `Task.detached` that reads `@TaskLocal`** — walk detached closure body for `@TaskLocal` property reads → bug (values will be nil). Important caveat for @concurrent migration
- [ ] **Find `withObservationTracking` with recursive `onChange`** — detect the specific pattern of `onChange: { self.observe() }` recursion → `Observations` candidate
- [ ] **Find `didSet`/`willSet` with side effects vs simple validation** — distinguish `didSet { NotificationCenter.post(...) }` (→ Observations) from `didSet { value = max(0, value) }` (keep as-is)
- [ ] **Find `static var` accessed from multiple isolation domains** — detect when a `static var` is referenced inside `@MainActor` and non-isolated contexts → needs synchronization
- [ ] **Find Unsafe*Pointer usage in functions that only read data** — if the pointer is never written through, `Span`/`RawSpan` is a direct replacement
- [ ] **Detect fixed-size tuple buffers** — find `(T, T, T, ...)` type annotations → `InlineArray` candidate

## AST nodes to visit
- `VariableDeclSyntax` with `weak` modifier — check for reassignment in enclosing type
- `FunctionCallExprSyntax` for `Task.detached`, `withObservationTracking`
- `AccessorBlockSyntax` — `didSet`/`willSet` accessor bodies
- `PatternBindingSyntax` with `static var` 
- `TupleTypeSyntax` — check if all elements are the same type (InlineArray candidate)

## Confidence levels
- `weak var` never reassigned → high
- `withObservationTracking` recursive pattern → high
- `Task.detached` → medium (may intentionally drop TaskLocal values)
- `didSet` with side effects → medium (agent verifies @Observable applicability)
- `static var` cross-isolation → medium (syntax-only, can't see actual isolation)
- Tuple → InlineArray → low (semantic choice, may be intentional)

## Summary of Changes
- Swift62ModernizationCheck detects Task.detached, weak var candidates, UnsafeBufferPointer, didSet/willSet side effects
