---
# e4f-izo
title: Audit visitor-state lifecycle
status: completed
type: task
priority: normal
created_at: 2026-04-25T20:43:12Z
updated_at: 2026-04-25T21:25:24Z
parent: 0ra-lks
sync:
    github:
        issue_number: "419"
        synced_at: "2026-04-25T22:35:10Z"
---

Some rules carry mutable state across visits that would leak if the rule instance were ever reused across files. Currently rules are constructed per-file, so this is latent — but worth documenting and/or hardening.

## Findings

- [x] `Sources/SwiftiomaticKit/Rules/Access/PreferFinalClasses.swift` — already overwrites `subclassedNames` at the top of `visit(_:SourceFileSyntax)` (always the visitor's first call), so it can't leak in current architecture. Added a `**Lifecycle**` doc-comment block on the property that names the invariant explicitly.
- [x] `Sources/SwiftiomaticKit/Rules/Redundant/RedundantSelf.swift` — added two balanced-scope helpers and routed every visit-method through them, eliminating the 38 raw `Stack.append` / `Stack.removeLast` calls and the matching `defer` blocks. Push/pop balance is now enforced by construction:
  - `withTypeContext(isReference:_:)` for `referenceTypeStack`.
  - `withScope(localNames:allowsImplicitSelf:_:)` for the paired `localNameStack` + `implicitSelfStack` frame.
  Doc-comments on the three stacks now state explicitly that they may only be touched through these helpers.

## Verification
- [x] Build clean.
- [x] Targeted tests pass: 78/78 (`RedundantSelf` + `PreferFinalClasses` suites).
- [ ] Skipped a "run twice in same instance" stress test. Rules are constructed per-file by the pipeline, so this is hypothetical; with the new helpers, the only way state could leak is if someone bypasses them, which would be visible in code review.

## Summary of Changes

**`PreferFinalClasses.swift`** — added a `Lifecycle` doc-comment on `subclassedNames` documenting that the per-file reset happens in `visit(_:SourceFileSyntax)` (the visitor's mandatory first call) and that rule instances are per-file.

**`RedundantSelf.swift`** — added two private helpers that own all stack mutation:

```swift
private func withTypeContext<T>(isReference: Bool, _ body: () -> T) -> T { ... }
private func withScope<T>(
  localNames: Set<String>, allowsImplicitSelf: Bool, _ body: () -> T
) -> T { ... }
```

Every visit override now calls one of these instead of doing manual `append` / `removeLast` with `defer`. Eight visit methods rewritten:

- 5× `withTypeContext` (`StructDeclSyntax`, `EnumDeclSyntax`, `ClassDeclSyntax`, `ActorDeclSyntax`, `ExtensionDeclSyntax`).
- 7× `withScope` (`FunctionDeclSyntax`, `InitializerDeclSyntax`, `SubscriptDeclSyntax`, `AccessorDeclSyntax`, `VariableDeclSyntax` lazy, `AccessorBlockSyntax` shorthand getter, `ClosureExprSyntax`).

Push/pop balance is now structural — `defer` lives inside the helper so callers can't omit it. Stack doc-comments name the helpers as the only legal mutation path. Behavior preserved, lines reduced.
