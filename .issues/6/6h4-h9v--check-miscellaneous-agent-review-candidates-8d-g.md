---
# 6h4-h9v
title: 'Check: Miscellaneous agent review candidates (§8d-g)'
status: completed
type: task
priority: normal
created_at: 2026-02-27T21:36:51Z
updated_at: 2026-02-27T21:50:03Z
parent: 52u-0w0
blocked_by:
    - w7e-hbx
---

SyntaxVisitor for the remaining §8 checks that benefit from AST but are simpler.

## 8d. Error types missing LocalizedError
- [ ] Find `enum Foo: Error` declarations (check `InheritanceClauseSyntax` for `Error`)
- [ ] Check if the same type or an extension in the same file conforms to `LocalizedError`
- [ ] AST advantage: grep can't distinguish `Error` in inheritance clause vs comment or string. AST can also check extensions
- [ ] Confidence: medium (internal errors may not need LocalizedError)

## 8e. Unused protocol conformances (CaseIterable)
- [ ] Find types conforming to `CaseIterable` (check `InheritanceClauseSyntax`)
- [ ] Cross-file pass 2: search for `.allCases` member access on that type name
- [ ] AST advantage: can trace the type name precisely, not just grep for the string
- [ ] Confidence: medium (usage may be in another module)

## 8f. `.absoluteString` usage
- [ ] Find `MemberAccessExprSyntax` with member name `absoluteString`
- [ ] AST advantage: can check the receiver expression — if it's constructed from `URL(fileURLWithPath:)`, it's almost certainly wrong
- [ ] Confidence: high when receiver is file URL, medium for unknown URLs

## 8g. `nonisolated(unsafe)` on Sendable values
- [ ] Find `VariableDeclSyntax` with `nonisolated(unsafe)` attribute and `let` binding
- [ ] Check if the initializer is a regex literal (`/pattern/`), enum case, or struct literal — these are Sendable in Swift 6.2
- [ ] AST advantage: can inspect the initializer expression type. Grep can only flag all `nonisolated(unsafe) let`
- [ ] Confidence: high for regex literals, medium for other value types

## Summary of Changes
- AgentReviewCheck covers §8b (fire-and-forget Task), §8d (Error without LocalizedError), §8f (.absoluteString), §8g (nonisolated(unsafe))
- Tests with fixture
