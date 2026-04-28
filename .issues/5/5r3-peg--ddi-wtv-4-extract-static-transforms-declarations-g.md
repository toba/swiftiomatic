---
# 5r3-peg
title: 'ddi-wtv-4: extract static transforms (Declarations + Generics + Hoist + Idioms + Literals)'
status: completed
type: task
priority: normal
created_at: 2026-04-28T02:42:45Z
updated_at: 2026-04-28T04:17:58Z
parent: ddi-wtv
blocked_by:
    - ogx-lb7
sync:
    github:
        issue_number: "490"
        synced_at: "2026-04-28T02:56:06Z"
---

Continuation of the mechanical refactor. Same pattern as ddi-wtv-3.

---

## Continuation Brief (for fresh sessions)

**Status:** 25/26 clean rules ported. Friction patterns resolved by `3zw-l17` (completed). Six clean rules remain — listed at the bottom of the Clean section. The remaining "deferred" rules (parent-walking + state) are now portable but optional: most of the perf win has already been captured, and structural-pass rules will keep running on legacy regardless.

### The 3-arg signature contract

Every ported rule exposes:

```swift
static func transform(
    _ node: ConcreteNodeType,
    parent: Syntax?,
    context: Context
) -> ReturnType
```

- `parent` is the original-tree parent of the node, captured by the caller *before* `super.visit` detaches. Read this when the rule walks ancestors; ignore it otherwise.
- `ReturnType` matches `SyntaxRewriter.visit(_ ConcreteNodeType)`'s return type — concrete for most, but erased to `DeclSyntax`/`ExprSyntax`/`StmtSyntax`/`TypeSyntax` for declaration/expression/statement/type kinds. The generator's `returnType(for:)` table in `CompactStageOneRewriterGenerator.swift` is authoritative.

The legacy `override func visit` shrinks to a delegator:

```swift
override func visit(_ node: ConcreteNodeType) -> ReturnType {
    let parent = Syntax(node).parent
    let visited = super.visit(node)
    guard let concrete = visited.as(ConcreteNodeType.self) else { return visited }
    return Self.transform(concrete, parent: parent, context: context)
}
```

For non-erased-return rules (override returns the same concrete kind), the unwrap is unnecessary:

```swift
override func visit(_ node: T) -> T {
    Self.transform(super.visit(node), parent: Syntax(node).parent, context: context)
}
```

### Findings inside `transform`

The static analog of `diagnose(_:on:...)` lives on `SyntaxRule` and is already implemented:

```swift
Self.diagnose(.someMessage, on: someNode, context: context)
```

`emitFinding` in `Sources/SwiftiomaticKit/Syntax/SyntaxRule.swift` is now `fileprivate static`; both instance and static `diagnose` route through it.

### Reference implementations to copy from

When porting, mimic these existing examples by structural shape:

- **Single visit, simple diagnose-only**: `Rules/Idioms/PreferIsDisjoint.swift`
- **Single visit, rewrite + parent walk**: `Rules/Idioms/PreferCountWhere.swift`, `Rules/Hoist/HoistAwait.swift`
- **Single visit, helper methods**: `Rules/Conditions/PreferCommaConditions.swift`, `Rules/Conditions/PreferIfElseChain.swift`
- **Multiple visits, multiple transforms**: `Rules/Declarations/StaticStructShouldBeEnum.swift`, `Rules/Idioms/AvoidNoneName.swift`, `Rules/Hoist/HoistTry.swift`
- **Erased-return + concrete-input**: `Rules/Access/PrivateStateVariables.swift`

For helpers, `sed -i '' 's/    private func /    private static func /g' <file>` quickly converts the instance helpers; check `context` is threaded through anything that diagnoses.

### Generator

- `Sources/GeneratorKit/RuleCollector.swift` — detects `static func transform(_:parent:context:)` shape; rules without that exact signature fall through to legacy `RewritePipeline`.
- `Sources/GeneratorKit/CompactStageOneRewriterGenerator.swift` — emits per-node `visit(_:)` overrides. The `declSyntaxKinds` / `exprSyntaxKinds` / `stmtSyntaxKinds` / `typeSyntaxKinds` sets drive return-type selection. If a node type isn't in any set, the generator assumes `T -> T`. Add to the appropriate set if you hit an "override does not override" build error.
- Output: `.build/plugins/outputs/swiftiomatic/SwiftiomaticKit/destination/GenerateCode/CompactStageOneRewriter+Generated.swift`

### Friction patterns (pick the disposition per rule)

| Pattern | Disposition |
|---|---|
| Parent-walking | Port using captured `parent: Syntax?`. Rewrite `node.parent` walks to start from `parent`. |
| Cross-visit instance state | **Skip** — leave on legacy. The rule's stored `private var` lives on the rewriter instance; static fns can't carry it. Add `[skip]` to the checklist. |
| Recursive `visit(...)` or `rewrite(...)` calls inside a visit body | **Skip** — leave on legacy. |

When skipping, ensure the rule's existing `override func visit` stays — the legacy `RewritePipeline` continues to run it as a separate pass.

### Verification

1. Run `xc-swift swift_diagnostics --build-tests` after each cluster batch — must be clean.
2. The combined rewriter is *not* yet wired into `RewriteCoordinator.runCompactPipeline` (still delegates to `RewritePipeline`). All ported rules continue to run via the legacy path until `g6t-gcm` flips the dispatch. So no behavior change should be observable in tests until cutover.
3. Spot-check the generated rewriter to confirm new rules appear:
   ```
   grep -E 'override func visit|YourNewRule' .build/plugins/outputs/swiftiomatic/SwiftiomaticKit/destination/GenerateCode/CompactStageOneRewriter+Generated.swift
   ```

### Remaining clean rules

Six remain, ordered by complexity:

1. `Hoist/CaseLet` (3 visits — `MatchingPatternConditionSyntax`, `SwitchCaseItemSyntax`, `ForStmtSyntax`; uses `ruleConfig` — replace with `context.configuration[Self.self]`)
2. `Generics/SimplifyGenericConstraints` (medium)
3. `Declarations/ModifierOrder` (4 visits)
4. `Idioms/PreferAssertionFailure` (3 visits)
5. `Generics/OpaqueGenericParameters` (3 visits, ~540 LoC — biggest)

After these, only the friction-flagged ones remain (which stay on legacy). At that point cluster `5r3-peg` is done.

---

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
- [x] `Declarations/ModifierOrder` (9 visits)
- [x] `Declarations/PreferMainAttribute` - AttributeSyntax
- [x] `Declarations/PreferSingleLinePropertyGetter` - PatternBindingSyntax
- [x] `Declarations/StaticStructShouldBeEnum` - StructDeclSyntax + ClassDeclSyntax
- [x] `Generics/OpaqueGenericParameters` (3 visits, large)
- [x] `Generics/PreferAngleBracketExtensions` - ExtensionDeclSyntax
- [x] `Generics/SimplifyGenericConstraints`
- [x] `Hoist/CaseLet` (3 visits)
- [x] `Hoist/IndirectEnum` - EnumDeclSyntax
- [x] `Idioms/AvoidNoneName` - EnumCaseElementSyntax + VariableDeclSyntax
- [x] `Idioms/NoExplicitOwnership` - FunctionDeclSyntax + AttributedTypeSyntax
- [x] `Idioms/PreferAssertionFailure` (1 visit)
- [x] `Idioms/PreferCompoundAssignment` - InfixOperatorExprSyntax
- [x] `Idioms/PreferDotZero` - FunctionCallExprSyntax
- [x] `Idioms/PreferFileID` - MacroExpansionExprSyntax
- [x] `Idioms/PreferIsEmpty` - InfixOperatorExprSyntax
- [x] `Idioms/PreferKeyPath` - FunctionCallExprSyntax
- [x] `Idioms/PreferStaticOverClassFunc` - ClassDeclSyntax
- [x] `Idioms/PreferWhereClausesInForLoops` - ForStmtSyntax
- [x] `Idioms/RequireFatalErrorMessage` - FunctionCallExprSyntax
- [x] `Literals/EmptyCollectionLiteral` - PatternBindingSyntax + FunctionParameterSyntax
- [x] `Literals/GroupNumericLiterals` - IntegerLiteralExprSyntax

### Parent-walking — defer to `3zw-l17` (7)

These rules read `node.parent` (or walk the ancestor chain). The combined rewriter's default ordering (super.visit before transform) detaches the node from its parent before transform runs, breaking these rules silently.

- [skip] `Declarations/ProtocolAccessorOrder`
- [x] `Hoist/HoistAwait` - FunctionCallExprSyntax (uses captured `parent` for ancestor walk)
- [x] `Hoist/HoistTry` - FunctionCallExprSyntax (parent walk via 3-arg signature; AwaitExpr re-ordering kept on legacy)
- [skip] `Idioms/NoAssignmentInExpressions`
- [skip] `Idioms/NoVoidTernary`
- [x] `Idioms/PreferCountWhere` - MemberAccessExprSyntax (uses captured parent)
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



## Summary of Changes

All 31 clean rules in cluster `5r3-peg` ported to the 3-arg `static func transform(_:parent:context:)` signature:

- `Generics/SimplifyGenericConstraints` — 5 visits (Function/Struct/Class/Enum/Actor)
- `Hoist/CaseLet` — 3 visits, helpers converted to static, `ruleConfig` → `context.configuration[Self.self]`
- `Idioms/PreferAssertionFailure` — 1 visit (brief said 3, only 1 in source)
- `Declarations/ModifierOrder` — 9 visits delegating to shared `reorderingModifiers` helper
- `Generics/OpaqueGenericParameters` — 3 visits + ~10 helper functions converted to static

Verified `xc-swift swift_diagnostics --build-tests` clean (9 pre-existing warnings, no errors). Generated `CompactStageOneRewriter+Generated.swift` references all five new rules.

Deferred (state / parent / recursive `rewrite()`) rules remain on legacy `RewritePipeline` per the brief — these are optional and can stay until cluster `r0w-l4r` and final cutover (`g6t-gcm`).
