---
# 5r3-peg
title: 'ddi-wtv-4: extract static transforms (Declarations + Generics + Hoist + Idioms + Literals)'
status: in-progress
type: task
priority: normal
created_at: 2026-04-28T02:42:45Z
updated_at: 2026-04-28T03:57:09Z
parent: ddi-wtv
blocked_by:
    - ogx-lb7
sync:
    github:
        issue_number: "490"
        synced_at: "2026-04-28T02:56:06Z"
---

Continuation of the mechanical refactor. Same pattern as ddi-wtv-3.

## Scope

- `Sources/SwiftiomaticKit/Rules/Declarations/` (8 RewriteSyntaxRule)
- `Sources/SwiftiomaticKit/Rules/Generics/` (3)
- `Sources/SwiftiomaticKit/Rules/Hoist/` (4)
- `Sources/SwiftiomaticKit/Rules/Idioms/` (20)
- `Sources/SwiftiomaticKit/Rules/Literals/` (3)

Total: 38 RewriteSyntaxRule subclasses.

## Friction audit

Per-rule audit (parent-walking, instance state, recursive visit() — friction patterns blocked on `3zw-l17`):

### Clean (26)

- [x] `Idioms/PreferIsDisjoint` - MemberAccessExprSyntax
- [x] `Idioms/PreferToggle` - InfixOperatorExprSyntax
- [x] `Declarations/EmptyExtensions` - CodeBlockItemListSyntax
- [x] `Declarations/InitCoderUnavailable` - InitializerDeclSyntax
- [ ] `Declarations/ModifierOrder` (4 visits)
- [x] `Declarations/PreferMainAttribute` - AttributeSyntax
- [x] `Declarations/PreferSingleLinePropertyGetter` - PatternBindingSyntax
- [x] `Declarations/StaticStructShouldBeEnum` - StructDeclSyntax + ClassDeclSyntax
- [ ] `Generics/OpaqueGenericParameters` (3 visits, large)
- [ ] `Generics/PreferAngleBracketExtensions`
- [ ] `Generics/SimplifyGenericConstraints`
- [ ] `Hoist/CaseLet` (3 visits)
- [x] `Hoist/IndirectEnum` - EnumDeclSyntax
- [x] `Idioms/AvoidNoneName` - EnumCaseElementSyntax + VariableDeclSyntax
- [x] `Idioms/NoExplicitOwnership` - FunctionDeclSyntax + AttributedTypeSyntax
- [ ] `Idioms/PreferAssertionFailure` (3 visits)
- [x] `Idioms/PreferCompoundAssignment` - InfixOperatorExprSyntax
- [x] `Idioms/PreferDotZero` - FunctionCallExprSyntax
- [x] `Idioms/PreferFileID` - MacroExpansionExprSyntax
- [x] `Idioms/PreferIsEmpty` - InfixOperatorExprSyntax
- [x] `Idioms/PreferKeyPath` - FunctionCallExprSyntax
- [x] `Idioms/PreferStaticOverClassFunc` - ClassDeclSyntax
- [ ] `Idioms/PreferWhereClausesInForLoops`
- [x] `Idioms/RequireFatalErrorMessage` - FunctionCallExprSyntax
- [ ] `Literals/EmptyCollectionLiteral`
- [ ] `Literals/GroupNumericLiterals`

### Parent-walking — defer to `3zw-l17` (7)

These rules read `node.parent` (or walk the ancestor chain). The combined rewriter's default ordering (super.visit before transform) detaches the node from its parent before transform runs, breaking these rules silently.

- [skip] `Declarations/ProtocolAccessorOrder`
- [x] `Hoist/HoistAwait` - FunctionCallExprSyntax (uses captured `parent` for ancestor walk)
- [x] `Hoist/HoistTry` - FunctionCallExprSyntax (parent walk via 3-arg signature; AwaitExpr re-ordering kept on legacy)
- [skip] `Idioms/NoAssignmentInExpressions`
- [skip] `Idioms/NoVoidTernary`
- [skip] `Idioms/PreferCountWhere`
- [skip] `Idioms/PreferExplicitFalse`

### Cross-visit instance state — defer to `3zw-l17` (5)

- [skip] `Declarations/OneDeclarationPerLine` (multiple nested rewriter classes with state)
- [skip] `Idioms/LeadingDotOperators` (`pendingLeadingTrivia`)
- [skip] `Idioms/PreferEnvironmentEntry` (collects keys across visits)
- [skip] `Idioms/PreferSelfType` (`typeContextDepth`)
- [skip] `Literals/URLMacro` (`madeReplacements`, `hasModuleImport`)

## Architectural finding

The static-transform model has three real friction patterns, listed above. **Parent-walking is the most pervasive**: 7 rules in this cluster alone, and the existing `Access/ACLConsistency` rule (already ported in `vz0-31g`) has the same issue but happens to work today because its legacy `visit` does pre-recursion (`super.visit(modified)` last). `3zw-l17` needs to decide:

- **(d) Pre-recursion ordering**: emit the combined rewriter as `Self.transform(node, context: context)` first, then `super.visit(transformed)`. Preserves parent access for the *first* transform invocation per node, but successive transforms in a chain see modified-but-detached nodes.
- **(e) Pass parent explicitly**: extend the `transform` signature to `transform(_ node: T, parent: Syntax?, context: Context)`. The combined rewriter captures `node.parent` before super.visit and forwards it.
- **(f) Per-rule opt-in to pre-recursion**: rules that need parent declare it via a static flag; generator emits two visit-body shapes accordingly.

(e) is the cleanest, but it changes the `transform` signature for every rule. Punt to triage.

## Done when

26 clean rules ported, friction list logged, follow-ups created on `3zw-l17`.
