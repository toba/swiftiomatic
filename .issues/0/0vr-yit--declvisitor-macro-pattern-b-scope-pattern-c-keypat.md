---
# 0vr-yit
title: '@DeclVisitor macro: Pattern B (scope) + Pattern C (KeyPath)'
status: ready
type: task
priority: normal
created_at: 2026-04-26T17:49:14Z
updated_at: 2026-04-26T17:49:14Z
parent: lhe-lqu
blocked_by:
    - j5a-lnn
sync:
    github:
        issue_number: "452"
        synced_at: "2026-04-26T18:08:49Z"
---

Phase 2 of `lhe-lqu`. Extends `@DeclVisitor` to cover the remaining two patterns identified in the parent issue. Blocked by `j5a-lnn` (Phase 1).

## Scope

Add a `style:` argument to the macro:

```swift
@DeclVisitor(.classDecl, .structDecl, style: .scoped(enter: "enterType", leave: "leaveType"))
@DeclVisitor(.functionDecl, .initializerDecl, style: .keyPath([
    .functionDecl: \FunctionDeclSyntax.funcKeyword,
    .initializerDecl: \InitializerDeclSyntax.initKeyword,
], helper: "collapseModifierLines"))
```

### Pattern B — scope push/pop

Generated body:

```swift
override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
    enterType(node)
    defer { leaveType() }
    return super.visit(node)
}
```

Reference rules: `RedundantSelf` (uses `withTypeContext`/`withScope`), `NestingDepth` (uses `enterType`/`leaveType`), `CyclomaticComplexity`. Verify the generated form matches the existing manual form on each.

### Pattern C — KeyPath dispatch

Generated body:

```swift
override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
    DeclSyntax(collapseModifierLines(of: node, keywordKeyPath: \.funcKeyword))
}
```

Reference rule: `ModifiersOnSameLine` (15 overrides, the canonical Pattern C consumer).

### Diagnostics + tests

- Diagnose: `style:` argument referencing a kind not in the kinds list; missing keypath entry for a kind in `.keyPath` style.
- Snapshot tests for each new style + each diagnostic.

### Escape hatch

For rules that chain multiple helpers per kind (e.g. `RedundantAccessControl`, `WrapMultilineStatementBraces`), the macro should not try to handle them. Document this as expected; those rules stay hand-written. Phase 3 will quantify how many rules fall into this bucket.

## Done when

- xc-swift package test passes.
- `RedundantSelf`, `NestingDepth`, and `ModifiersOnSameLine` migrated as exemplars and produce identical findings.
- Snapshot tests cover Patterns B and C plus their diagnostics.

## References

- See parent `lhe-lqu` "Implementation plan (2026-04-26)" section for the full macro surface design.
