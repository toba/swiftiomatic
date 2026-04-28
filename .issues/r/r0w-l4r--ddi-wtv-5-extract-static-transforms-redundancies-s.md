---
# r0w-l4r
title: 'ddi-wtv-5: extract static transforms (Redundancies + Sort + Wrap + remaining)'
status: ready
type: task
priority: normal
created_at: 2026-04-28T02:42:46Z
updated_at: 2026-04-28T04:10:20Z
parent: ddi-wtv
blocked_by:
    - ogx-lb7
sync:
    github:
        issue_number: "494"
        synced_at: "2026-04-28T02:56:06Z"
---

Final mechanical refactor batch — see `5r3-peg` for the previous cluster's continuation brief; the same contract applies here. The friction blocker (`3zw-l17`) is resolved.

## Continuation Brief (for fresh sessions)

**Status:** Not started. ~69 RewriteSyntaxRule subclasses across 6 directories. Friction patterns audited (see categorization below).

### The 3-arg signature contract

Every ported rule exposes:

```swift
static func transform(
    _ node: ConcreteNodeType,
    parent: Syntax?,
    context: Context
) -> ReturnType
```

The legacy `override func visit` shrinks to a delegator. See `5r3-peg`'s continuation brief for the exact templates and reference implementations to copy from.

Findings inside `transform` use `Self.diagnose(.message, on: node, context: context)`.

### Generator

- `Sources/GeneratorKit/CompactStageOneRewriterGenerator.swift` — return-type detection table needs additions if any new node type isn't in `declSyntaxKinds` / `exprSyntaxKinds` / `stmtSyntaxKinds` / `typeSyntaxKinds`. Build error `method does not override any method from its superclass` indicates a missing kind.
- Output: `.build/plugins/outputs/.../CompactStageOneRewriter+Generated.swift`

## Scope

- `Sources/SwiftiomaticKit/Rules/Redundancies/` — 36 RewriteSyntaxRule
- `Sources/SwiftiomaticKit/Rules/Sort/` — 4 (all structural-pass; **skip all**)
- `Sources/SwiftiomaticKit/Rules/Wrap/` — 11
- `Sources/SwiftiomaticKit/Rules/LineBreaks/` — 2
- `Sources/SwiftiomaticKit/Rules/Comments/` — 6
- `Sources/SwiftiomaticKit/Rules/Testing/` — 5

Total to consider: ~64 (excluding Sort, which stays as ordered structural passes per `g6t-gcm`).

## Per-rule audit (from `3zw-l17` Phase 1 audit)

### Clean — port these (40+)

**Redundancies** (~24 clean of 36):
- `RedundantAsync`, `RedundantBreak`, `RedundantClosure`, `RedundantEnumerated`, `RedundantEquatable`, `RedundantInit`, `RedundantLetError`, `RedundantNilCoalescing`, `RedundantNilInit`, `RedundantObjc`, `RedundantOptionalBinding`, `RedundantPattern`, `RedundantProperty`, `RedundantRawValues`, `RedundantReturn`, `RedundantSendable`, `RedundantThrows`, `RedundantTypedThrows`, `RedundantType`, `RedundantViewBuilder`, `NoBacktickedSelf`, `NoLabelsInCasePatterns`, `UseImplicitInit`, `RedundantSetterACL` (1 parent walk — port with `parent:`)

**Wrap** (4 clean of 11):
- `WrapSwitchCaseBodies`, `CollapseSimpleEnums`, `WrapCompoundCaseItems`, `WrapConditionalAssignment`

**LineBreaks** (1 clean of 2):
- `ModifiersOnSameLine`

**Comments** (3 clean of 6):
- `DocCommentsPrecedeModifiers`, `TripleSlashDocComments`, `FormatSpecialComments`

**Testing** (1 clean of 5):
- `TestSuiteAccessControl`

### Parent-walking — port with `parent:` (8)

- `Redundancies/RedundantBackticks` (15 parent walks — heaviest in cluster)
- `Redundancies/RedundantLet` (5)
- `Redundancies/RedundantStaticSelf` (5)
- `Redundancies/UnusedArguments` (3)
- `Wrap/CollapseSimpleIfElse` (1)
- `Wrap/WrapTernary` (1)
- `Wrap/WrapSingleLineComments` (1)
- `Wrap/WrapSingleLineBodies` (3)
- `Comments/ConvertRegularCommentToDocC` (2 — but **also structural**, skip)
- `Comments/ReflowComments` (1 — but **also structural**, skip)

### Cross-visit instance state — skip (7)

Leave these on legacy. Their state lives on the rewriter instance.

- `Redundancies/RedundantAccessControl` (file-structure phase tracking)
- `Redundancies/RedundantSelf` (3 scope stacks)
- `Testing/NoGuardInTests` (3 vars)
- `Testing/PreferSwiftTesting` (5 vars)
- `Testing/SwiftTestingTestCaseNames` (2 vars)
- `Testing/ValidateTestCases` (1 var)
- (Plus state-bearing `WrapMultilineFunctionChains` / `WrapMultilineStatementBraces` / `KeepFunctionOutputTogether` — confirm they're `RewriteSyntaxRule` first; some are `LayoutRule`.)

### Recursive `rewrite(...)` — skip (1)

- `Redundancies/NoSemicolons` (calls `rewrite()` mid-visit)

### Structural-pass — skip (8)

These run as ordered passes in `g6t-gcm`, never via the combined rewriter:

- `Sort/SortImports`, `Sort/SortDeclarations`, `Sort/SortSwitchCases`, `Sort/SortTypeAliases`
- `Comments/FileHeader`, `Comments/ConvertRegularCommentToDocC`, `Comments/ReflowComments`
- `BlankLines/BlankLinesAfterImports` (if present in this cluster)

## Verification

After each batch:

```
xc-swift swift_diagnostics --build-tests
```

The combined rewriter still isn't wired in (`g6t-gcm` does that), so all behavior continues to flow through legacy `RewritePipeline`. No test diffs expected.

## Done when

All clean + parent-walking rules expose the 3-arg `transform`. Friction rules confirmed `[skip]` with their pattern documented. Build + tests green.
