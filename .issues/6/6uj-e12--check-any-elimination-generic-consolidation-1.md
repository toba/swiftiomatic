---
# 6uj-e12
title: 'Check: Any elimination & generic consolidation (§1)'
status: completed
type: task
priority: normal
created_at: 2026-02-27T21:33:03Z
updated_at: 2026-02-27T21:49:56Z
parent: 52u-0w0
blocked_by:
    - w7e-hbx
sync:
    github:
        issue_number: "71"
        synced_at: "2026-03-01T01:01:43Z"
---

SyntaxVisitor that detects type erasure and generic consolidation opportunities.

## What grep does today
- Matches `: Any`, `AnyObject`, `AnyHashable`, `[String: Any]`
- Matches `as!` / `as?` casts
- Matches `@unchecked Sendable`

## What AST enables beyond grep
- [ ] **Distinguish `Any` in type annotations vs comments/strings** — grep can't tell `// returns Any` from `-> Any`
- [ ] **Trace `as?`/`as!` back to the erased source** — find where the type was erased and suggest preserving it
- [ ] **Find `[String: Any]` used as structured data** — check if all keys are string literals (candidate for Codable struct)
- [ ] **Detect `any Protocol` parameters where `some Protocol` suffices** — check if the existential is opened (used generically) or boxed
- [ ] **Find overloaded functions with identical bodies** — compare function body ASTs that differ only in type annotations (generic consolidation candidate)
- [ ] **Detect `@unchecked Sendable` on types using Mutex** — if all mutable state is behind `Mutex<>`, `@unchecked` can likely be removed

## AST nodes to visit
- `TypeAnnotationSyntax` — check for `Any`, `AnyObject`, `AnyHashable`
- `AsExprSyntax` — `as?` / `as!` casts
- `AttributeSyntax` — `@unchecked`
- `FunctionDeclSyntax` — compare signatures and bodies for consolidation
- `SomeOrAnyTypeSyntax` — `any Protocol` vs `some Protocol`

## Confidence levels
- `Any` in type annotation → high
- `as?`/`as!` cast → high
- `@unchecked Sendable` → medium (may be intentional for Obj-C interop)
- Overloaded function consolidation → medium (bodies may differ subtly)

## Summary of Changes
- AnyEliminationCheck detects Any/AnyObject type annotations, [String: Any] dictionaries, as! force casts
