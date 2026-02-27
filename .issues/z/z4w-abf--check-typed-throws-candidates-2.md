---
# z4w-abf
title: 'Check: Typed throws candidates (§2)'
status: completed
type: task
priority: normal
created_at: 2026-02-27T21:33:19Z
updated_at: 2026-02-27T21:49:56Z
parent: 52u-0w0
blocked_by:
    - w7e-hbx
---

SyntaxVisitor that identifies typed throws opportunities.

## What grep does today
- Matches `catch let _ as SpecificError`
- Matches untyped `throws` declarations (PCRE negative lookahead for `throws(`)
- Flags `Result<` as opportunity

## What AST enables beyond grep
- [ ] **Trace all `throw` sites in a function body** — if every `throw` uses the same error type, the function is a typed throws candidate. Grep can only find `throws` keyword, not what's thrown
- [ ] **Detect single-error-type catch blocks** — find `do/catch` where every `catch` pattern matches the same error type
- [ ] **Find `Result<T, E>` return types that could be typed throws** — verify the Result is returned immediately (not stored in collections or passed as values)
- [ ] **Detect `rethrows` functions** — check if the rethrown error could be typed
- [ ] **Map error type hierarchies** — find error enums and which functions throw them, suggesting typed throws annotations

## AST nodes to visit
- `FunctionDeclSyntax` — check `signature.effectSpecifiers?.throwsClause` for untyped `throws`
- `ThrowStmtSyntax` — collect the thrown expression's type (via `FunctionCallExprSyntax` pattern matching)
- `CatchClauseSyntax` — check catch patterns for type casts
- `FunctionTypeSyntax` with `ReturnClauseSyntax` — find `Result<>` return types

## Confidence levels
- All throw sites use same error type → high
- Single catch-and-cast pattern → high  
- `Result<>` return → medium (may be intentionally stored as value)
- `rethrows` → low (complex to verify)

## Summary of Changes
- TypedThrowsCheck detects single-error-type functions with untyped throws
- ThrowCollector walks function bodies, skips nested closures
- Tests with fixture covering positive and negative cases
