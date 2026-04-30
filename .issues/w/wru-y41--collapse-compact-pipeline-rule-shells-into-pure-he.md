---
# wru-y41
title: Collapse compact-pipeline rule shells into pure helpers
status: completed
type: feature
priority: high
created_at: 2026-04-29T19:44:53Z
updated_at: 2026-04-29T22:45:09Z
parent: iv7-r5g
blocked_by:
    - ddi-wtv
sync:
    github:
        issue_number: "509"
        synced_at: "2026-04-30T00:29:45Z"
---

## Goal

Once `ddi-wtv` (Phase 4g) lands and the legacy `RewritePipeline` is gone, collapse the remaining rule-class shells in the compact pipeline into pure file-private helpers. Delete `RuleCollector`'s `nodeLocal*` collections + `CompactStageOneRewriterGenerator` + `applyRule` + `RewriteSyntaxRule` + `Context.ruleState(for:)`. The merged `Rewrites/<Group>/<NodeType>.swift` dispatchers + per-rule helper files become the entire stage-1 pipeline.

## Motivation

After `ddi-wtv`, the typical rewrite rule is a 28-line shell:

```swift
final class RedundantOverride: RewriteSyntaxRule<BasicRuleValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .redundancies }
    override class var defaultValue: BasicRuleValue { BasicRuleValue(rewrite: false, lint: .warn) }
    static func transform(_ node: FunctionDeclSyntax, parent: Syntax?, context: Context) -> DeclSyntax {
        applyRedundantOverride(node, parent: parent, context: context)
    }
}
```

The class:

- Inherits from `RewriteSyntaxRule<V>: SyntaxRewriter` — `visitAny` is dead in the compact pipeline.
- Exists as a *type identity* so `RuleCollector` can find it, `context.shouldFormat(_:node:)` can gate it, and `Context.ruleState(for:)` can key state by it.
- Hangs `static transform` / `willEnter` / `didExit` off something the AST scanner can recognize.

In the compact-style world, all rules always run, the set is closed, and there's exactly one dispatcher. The discoverability machinery (RuleCollector → generator → dispatcher) was justified when rules were a public, individually-toggleable surface; now it's pure overhead.

## Target shape

### Per rule: one file, no class

`Sources/SwiftiomaticKit/Rewrites/Decls/RedundantOverride.swift` (replaces both the rule shell and `RedundantOverrideHelpers.swift`):

```swift
import SwiftSyntax

private let category = "RedundantOverride"

private let excludedMethods: Set<String> = [
    "setUp", "setUpWithError", "tearDown", "tearDownWithError",
    "viewDidLoad", "viewWillAppear", /* … */
]

func rewriteRedundantOverride(_ node: FunctionDeclSyntax, context: Context) -> DeclSyntax {
    guard !excludedMethods.contains(node.name.text),
        isRedundantFunctionOverride(node)
    else {
        return DeclSyntax(node)
    }
    let overrideToken = node.modifiers.first { $0.name.tokenKind == .keyword(.override) }?.name
        ?? node.funcKeyword
    context.diagnose(
        .removeRedundantOverride(name: node.name.text),
        category: category,
        on: overrideToken
    )
    return removed(node)
}

private func isRedundantFunctionOverride(_ node: FunctionDeclSyntax) -> Bool { /* … */ }
private func extractCall(from item: CodeBlockItemSyntax) -> FunctionCallExprSyntax? { /* … */ }
private func unwrapCall(_ expr: ExprSyntax) -> FunctionCallExprSyntax? { /* … */ }
private func removed(_ node: some DeclSyntaxProtocol) -> DeclSyntax { /* … */ }

extension Finding.Message {
    fileprivate static func removeRedundantOverride(name: String) -> Finding.Message {
        "remove redundant override of '\(name)'; it only forwards to super with identical arguments"
    }
}
```

What disappeared: rule class shell, `parent:` param (most rules ignore it), prefixed helper names (file-private + file scope is the namespace), `RedundantOverride.diagnose(...)` (replaced by `context.diagnose(_:category:on:)` taking a string category), config-key registration for parameterless rules.

### Dispatcher: direct calls, no `applyRule`

`Sources/SwiftiomaticKit/Rewrites/Decls/FunctionDecl.swift`:

```swift
func rewriteFunctionDecl(_ node: FunctionDeclSyntax, context: Context) -> DeclSyntax {
    var result = node
    result = rewriteDocCommentsPrecedeModifiers(result, context: context)
    result = rewriteModifierOrder(result, context: context)
    result = rewriteModifiersOnSameLine(result, context: context)
    // … 14 more direct calls …

    result = noForceTryAfterFunctionDecl(result, context: context)
    result = noForceUnwrapAfterFunctionDecl(result, context: context)

    result = rewriteRedundantEscaping(result, context: context)
    result = rewriteWrapMultilineStatementBraces(result, context: context)
    result = rewriteWrapSingleLineBodies(result, context: context)

    let widened = rewritePreferSwiftTesting(result, context: context)
    guard let stillFunc = widened.as(FunctionDeclSyntax.self) else { return widened }
    result = stillFunc

    return rewriteRedundantOverride(result, context: context)
}
```

No `applyRule(R.self, to: &result, parent:, context:, transform: R.transform)` ladder. No `context.shouldFormat(R.self, …)` gating — under compact every pass runs unconditionally; `// sm:ignore` checks happen inside the rule helper via category string against `RuleMask`.

### State hooks: hand-written aggregators

`Sources/SwiftiomaticKit/Rewrites/CompactStageOneRewriter.swift` (hand-written; replaces the generated dispatcher):

```swift
final class CompactStageOneRewriter: SyntaxRewriter {
    let context: Context
    init(context: Context) { self.context = context }

    override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
        enterFunctionDecl(node, context: context)
        let visited = super.visit(node)
        defer { exitFunctionDecl(context: context) }
        guard let typed = visited.as(FunctionDeclSyntax.self) else { return visited }
        return rewriteFunctionDecl(typed, context: context)
    }
    // ~30-40 overrides total, hand-written.
}
```

Per-pass state contributors live alongside their rule (`Rewrites/Exprs/NoForceTry.swift`):

```swift
private func enterFunctionDecl_NoForceTry(_ node: FunctionDeclSyntax, context: Context) { /* push */ }
private func exitFunctionDecl_NoForceTry(context: Context) { /* pop */ }
```

A small aggregator per node type wires them in (`Rewrites/Decls/FunctionDecl+State.swift`):

```swift
func enterFunctionDecl(_ node: FunctionDeclSyntax, context: Context) {
    enterFunctionDecl_NoForceTry(node, context: context)
    enterFunctionDecl_NoForceUnwrap(node, context: context)
    enterFunctionDecl_RedundantSelf(node, context: context)
}
func exitFunctionDecl(context: Context) {
    exitFunctionDecl_RedundantSelf(context: context)
    exitFunctionDecl_NoForceUnwrap(context: context)
    exitFunctionDecl_NoForceTry(context: context)
}
```

`Context.ruleState(for:)` (keyed by metatype) → typed state stored directly on `Context` (one property per stateful pass — `noForceTryState`, `noForceUnwrapState`, `redundantSelfState`).

## What gets deleted

| Today | After |
|---|---|
| `Sources/.../Rules/<Group>/<Foo>.swift` shells (~120 files) | gone |
| `Sources/.../Rewrites/<Group>/<Foo>Helpers.swift` | renamed to `<Foo>.swift` (no `Helpers` suffix) |
| `applyRule<R, N, Out>(...)` in `RewriteHelpers.swift` | gone |
| `RuleCollector.nodeLocalTransforms / nodeLocalWillEnter / nodeLocalDidExit` | gone |
| `CompactStageOneRewriterGenerator` (entire file) | gone |
| `RewriteSyntaxRule<V>` base class + `visitAny` | gone (4g already plans to delete) |
| `Context.ruleState(for:)` (metatype-keyed) | typed state properties on `Context` |
| `context.shouldFormat(R.self, node:)` calls in dispatchers | gone |

## What stays

- **Lint side** (`LintSyntaxRule`, `LintPipeline`) — out of scope. Per-rule severity / `// sm:ignore <rule>` / `list-rules` need per-rule type identity. Not conflated.
- **Structural-pass rewrites** (`SortImports`, `BlankLinesAfterImports`, `ExtensionAccessLevel`, `FileScopedDeclarationPrivacy`, `FileHeader`, `CaseLet`, etc.) — plain `SyntaxRewriter` subclasses; rule shells optional but not in scope here.
- **`PreferShorthandTypeNames`** — the recursion is fundamental; stays as a small `SyntaxRewriter` subclass invoked from the dispatcher.
- **`// sm:ignore` directive** — keeps working, gated on the category string instead of metatype.
- **Findings categorisation** — `SyntaxFindingCategory(name: String)` constructor (the metatype-based one goes away on the rewrite side; lint side keeps the metatype constructor).

## Compact-style configuration

For the few rewrites that take parameters today (e.g. `NestedCallLayout.mode`), per-rule config types collapse into a single `CompactStyle.Configuration` struct (or stay as nested types under it). Helpers read from `context.compactConfig.nestedCallLayout.mode` directly. No metatype-keyed registry, no per-rule key strings.

## Migration order

Each step keeps the build green and tests on the parity bar.

1. **Pre-req**: `ddi-wtv` Phase 4g lands (legacy `RewritePipeline` deleted).
2. **Hand-write `CompactStageOneRewriter`**; delete `CompactStageOneRewriterGenerator`; delete the `nodeLocal*` collections in `RuleCollector`.
3. **Inline `applyRule(...)` ladders** — mechanical edit per dispatcher file. Drop `shouldFormat` gating in the same pass.
4. **Per-group sweep** (e.g. `Rewrites/Decls/`):
   - Fold rule shell into the helpers file.
   - Rename `applyFoo` → `rewriteFoo`.
   - Drop unused `parent:` params.
   - Swap `Foo.diagnose(...)` → `context.diagnose(..., category: "Foo")`.
   - Delete `Sources/.../Rules/<Group>/Foo.swift`.
5. **Migrate state-aware rules last** — `NoForceTry`, `NoForceUnwrap`, `RedundantSelf` need `enterFunctionDecl` / `exitFunctionDecl` aggregators in place before their `willEnter`/`didExit` hooks become aggregator-contributor functions. Replace `Context.ruleState(for:)` lookups with typed state properties on `Context`.
6. **Delete final scaffolding**: `RewriteSyntaxRule`, `applyRule`, `Context.ruleState(for:)`, `static transform` detection in `RuleCollector`, the rewrite half of `Pipelines+Generated.swift` if anything's left.

## Out of scope

- Lint-rule shells (separate concern; lints already use the model the rewrite side is moving toward).
- Structural-pass rule shells (don't depend on this work; could follow as a separate cleanup).
- Public configuration redesign beyond what's needed to drop per-rewrite-rule config types — `o72-vx7` already covers the `style` + universal-parameters schema.



## Current-state audit (session 2026-04-29)

Reading the actual code, the picture is more advanced than the issue body assumed at creation time:

- **`StaticFormatRule<V>` already exists** (`Sources/SwiftiomaticKit/Syntax/StaticFormatRule.swift`) — registration-only base, no `SyntaxRewriter` machinery. **127 of the ~140 rewrite rules already use it.** Only 10 still inherit from `RewriteSyntaxRule`, all of them structural-pass rules + `PreferShorthandTypeNames` (out of scope per the original issue body).
- **`SyntaxRule` protocol is already split** into bare `SyntaxRule` (no instance) and `InstanceSyntaxRule` (lint + structural rewriters).
- **Hand-written dispatchers** in `Rewrites/<Group>/<NodeType>.swift` already exist; `CompactStageOneRewriter` is generated. `applyRule(R.self, ...)` ladders are still the common shape.
- **13 `*Helpers.swift` files** under `Rewrites/` — these are the rules whose logic was lifted out into free functions. The other ~115 `StaticFormatRule` users keep their logic as `private static func` on the rule class, which is already the simpler shape. **The "fold helpers back into rule file" sub-task is the smallest meaningful win.**

### Concrete remaining work

1. **Fold the 13 `*Helpers.swift` files back into their rule shells.** Recipe: lift free `apply<Rule>` to `static func transform`, lift prefixed helpers (`<rule>Foo`) to `private static func foo` on the class, drop the `Helpers` file. One-rule-per-file is the target. Pattern proven on `RedundantOverride` — see below.
2. **Inline `applyRule(R.self, to: &result, ...)` ladders** in dispatchers to direct `if context.shouldFormat(R.self, ...) { result = R.transform(result, ..., context).as(...) ?? result }`. (Or — once category-string gating is in place, drop `shouldFormat` calls and gate inside each `transform` against the rule mask.)
3. **Replace `Context.ruleState(for:)` (metatype-keyed)** with typed state on `Context`.
4. **Hand-write `CompactStageOneRewriter`** to replace the generator (1227 generated lines, but most overrides follow one of two simple shapes).
5. **Delete `RewriteSyntaxRule` + the legacy detection paths in `RuleCollector`** once the structural-pass rules are migrated to plain `SyntaxRewriter` subclasses (out of scope here).

### Session 1 progress (RedundantOverride exemplar)

Folded `Sources/SwiftiomaticKit/Rewrites/Decls/RedundantOverrideHelpers.swift` (157 lines) back into `Sources/SwiftiomaticKit/Rules/Redundancies/RedundantOverride.swift`:

- **Before**: 30-line shell + 157-line helpers file (two files, prefixed free functions like `redundantOverrideForwardsToSuper`).
- **After**: single 157-line rule file. Helpers became `private static func` on the class (`forwardsToSuper`, `hasOverride`, `extractCall`, `unwrapCall`, `removed`). Excluded-methods set became `private static let excludedMethods`. `Finding.Message` extension stayed at file scope as fileprivate.
- Verification: `xc-swift swift_diagnostics --no-include-lint` clean (12 warnings, baseline). `RedundantOverride` filter — 9 pass, 0 fail.

This pattern is now the recipe for the remaining 12 helper-files. They cluster in three categories:

- **Stateless** (~8 files): `ConvertRegularCommentToDocCHelpers`, `RedundantEscapingHelpers`, `PreferFinalClassesHelpers`, `ReflowCommentsHelpers`, etc. Same recipe as `RedundantOverride` — pure mechanical lift.
- **Stateful** (~3 files): `NoForceTryHelpers`, `NoForceUnwrapHelpers`, `RedundantSelf` (state class). Helper file holds a reference-typed state class read via `Context.ruleState(for:)`. State class moves onto the rule class as a nested type; `willEnter`/`didExit`/`transform` all become static methods on the rule.
- **Multi-caller** (~2 files): `NoParensAroundConditionsHelpers` (8 callers), `NamedClosureParamsHelpers`. These have multiple node-type entry points calling shared helpers — fold target is one rule file with multiple `static transform` overloads.



## Session 2 — Hand-write `CompactStageOneRewriter`, delete generator

Replaced the generated `CompactStageOneRewriter+Generated.swift` (1227 lines) with a hand-written `Sources/SwiftiomaticKit/Rewrites/CompactStageOneRewriter.swift`. Behavior identical (file copied verbatim from the last generator output, with the auto-generation banner stripped).

### Changes

- **Created** `Sources/SwiftiomaticKit/Rewrites/CompactStageOneRewriter.swift` — 1226-line hand-written dispatcher (was the generator's last output, minus the "automatically generated" banner).
- **Deleted** `Sources/GeneratorKit/CompactStageOneRewriterGenerator.swift`.
- **Removed** `compactStageOneRewriterFile` from `Sources/GeneratorKit/GeneratePaths.swift`.
- **Removed** `CompactStageOneRewriterGenerator(...).generateFile(...)` from `Sources/Generator/main.swift`.
- **Removed** `CompactStageOneRewriter+Generated.swift` from `Plugins/GeneratePlugin/plugin.swift`'s `outputFiles` list (5 → 4 generated files).

### Verification

- `xc-swift swift_diagnostics --no-include-lint` — Build succeeded, 12 warnings (unchanged baseline).
- Full test suite — pass except the 2 pre-existing `GuardStmtTests` pretty-printer-idempotency failures (`optionalBindingConditions`, `breaksElseWhenInlineBodyExceedsLineLength`), unrelated to this change.

### What this unlocks

The dispatcher is now editable. Future edits land in `CompactStageOneRewriter.swift` directly — no `RuleCollector` introspection, no AST scanning of `static transform`/`willEnter`/`didExit` to wire rules into the dispatcher. New rules opt in by **adding their dispatch line by hand** in the relevant `visit(_ T)` override.

### Cleanup follow-ups (non-blocking)

- **Stale doc-comment references** to `CompactStageOneRewriterGenerator.manuallyHandledNodeTypes` in ~30 files under `Sources/SwiftiomaticKit/Rewrites/<Group>/<NodeType>.swift`. Cosmetic.
- **Dead code in `RuleCollector`** — `nodeLocalTransforms` / `nodeLocalWillEnter` / `nodeLocalDidExit` collections + the per-rule `transformedNodes` / `willEnterNodes` / `didExitNodes` extraction in `detectSyntaxRule`. No remaining consumers; safe to delete.
- **Indentation** — the hand-written file uses 2-space indents per the original generator output. `Rewrites/<Group>/<NodeType>.swift` files use 4-space. Reformat once for consistency.
- **Stage 4 of the original plan** (drop `applyRule` + `shouldFormat` ladders, replace with direct calls / category-string gating) — still applies on top of the now-hand-written dispatcher.



## Session 2 (continued) — RuleCollector dead code stripped

Removed the now-unused compact-pipeline collection paths from `RuleCollector`:

- **`RuleCollector.swift`**: dropped `nodeLocalTransforms` / `nodeLocalWillEnter` / `nodeLocalDidExit` dictionaries; dropped the matching extraction loop in `detectSyntaxRule` (transform / willEnter / didExit AST detection ~70 lines); collapsed the `for member in allMembers` loop with same-file extension scan to a 5-line `for member in members` visit-only loop (rules using same-file extensions for visit-method discovery aren't a thing, so the extension-merge was only needed for the now-irrelevant transform/willEnter/didExit hooks).
- **`RuleCollector+DetectedRule.swift`**: dropped `transformedNodes` / `willEnterNodes` / `didExitNodes` properties from `DetectedSyntaxRule`.

`RuleCollector` is now ~70 lines smaller and only does what it needs to: detect rule types, their visit nodes, opt-in flags, custom config properties.

### Verification

- `xc-swift swift_diagnostics --no-include-lint` — Build succeeded, 12 warnings (unchanged baseline).

### Still in cleanup queue

- ~34 dispatcher files with stale `CompactStageOneRewriterGenerator.manuallyHandledNodeTypes` doc-comment references — cosmetic, mass-edit when convenient.
- Reformat `CompactStageOneRewriter.swift` from 2-space → 4-space indent for consistency with the rest of `Rewrites/`.
- Stage 4 (drop `applyRule` ladders + `shouldFormat` gating, replace with direct calls / category-string gating).



## Session 2 (continued) — two more helpers folded

- **`ConvertRegularCommentToDocC`**: 31-line shell + 223-line helpers → single 230-line rule file. All free helpers became `private static func` on the class. `directivePrefixes` constant became `private static let`. `Self.diagnose` replaces `ConvertRegularCommentToDocC.diagnose`. **Verified**: 29 tests pass.
- **`BlankLinesBeforeControlFlowBlocks`**: 46-line shell + 97-line helpers → single 117-line rule file. Multi-caller helper (called from CodeBlock + SwitchCase dispatchers + own `willEnter` hooks) — moved onto the rule class as `static func insertBlankLines(...)`. Updated 2 dispatcher call sites: `blankLinesBeforeControlFlowInsertBlankLines(...)` → `BlankLinesBeforeControlFlowBlocks.insertBlankLines(...)`. **Verified**: 93 BlankLines tests pass.

### Remaining helpers (10 of original 13)

By size:
- 62 `NamedClosureParamsHelpers`
- 62 `NoParensAroundConditionsHelpers` (multi-caller, 8 call sites)
- 66 `RedundantSwiftTestingSuiteHelpers` (file-level state)
- 155 `PreferFinalClassesHelpers` (file-level state)
- 161 `NoForceTryHelpers` (state class)
- 210 `ReflowCommentsHelpers` (stateless)
- 242 `RedundantEscapingHelpers` (state class)
- 369 `WrapMultilineStatementBracesHelpers` (stateless, 15 transform overloads)
- 641 `NoForceUnwrapHelpers` (state class)
- 697 `NestedCallLayoutHelpers` (stateless, biggest)



## Session 2 (continued, batch 3) — two more helpers folded

- **`NamedClosureParams`**: state class + free helpers folded onto rule class. `NamedClosureParamsState` → nested `State` type. Free `namedClosureParamsState/PushClosure/PopClosure/RewriteDeclReference` → `static` methods on `NamedClosureParams` (`willEnter`/`didExit` shape now reads naturally without trampoline calls). Updated 1 dispatcher caller (`DeclReferenceExpr.swift`). Tests pass.
- **`RedundantSwiftTestingSuite`**: state class + 2 free helpers folded onto rule class. Updated 5 dispatcher callers (`ImportDecl`, `EnumDecl`, `StructDecl`, `ClassDecl`, `ActorDecl`). `Self.diagnose` replaces `RedundantSwiftTestingSuite.diagnose`. Tests pass.

### Cumulative so far

- 5 of 13 helpers files folded: `RedundantOverride`, `ConvertRegularCommentToDocC`, `BlankLinesBeforeControlFlowBlocks`, `NamedClosureParams`, `RedundantSwiftTestingSuite`.
- Generator path (`CompactStageOneRewriter+Generated.swift`) replaced by hand-written file. `RuleCollector` ~70 lines smaller.
- Build clean (12 warnings baseline) at every step. Combined: 156 tests pass across the touched rules.

### Pattern for state-bearing rules

Multi-caller helpers + file-level state convert cleanly:

1. `final class FooState` → nested `final class State` on the rule.
2. `func fooState(_ context:)` → `static func state(_ context:)` returning `State` (uses `context.ruleState(for: Self.self) { State() }`).
3. `func fooDoThing(...)` → `static func doThing(...)` on the rule.
4. Update each external caller `fooDoThing(...)` → `Foo.doThing(...)`.
5. Replace `Foo.diagnose(...)` with `Self.diagnose(...)` since it's now inside the rule's class.



## Session 2 (continued, batch 4) — `NoParensAroundConditions` folded

Largest multi-caller helper to date — 8 dispatcher callers across 7 files plus 5 `willEnter` hooks on the rule itself.

- **`NoParensAroundConditions`**: 62-line helpers + 58-line shell → single 113-line rule file. `noParensMinimalSingleExpression`/`noParensFixKeywordTrailingTrivia` → `static func minimalSingleExpression`/`fixKeywordTrailingTrivia` on the rule. Updated 8 dispatcher callers in `Stmts/{WhileStmt,ReturnStmt,RepeatStmt,ConditionElement,IfExpr,SwitchExpr,GuardStmt}.swift` and `Exprs/InitializerClause.swift`. Tests pass (25/25).

### Cumulative

- **6 of 13 helpers files folded.** `RewriteHelpers.swift` (the `applyRule` wrapper) is the only `*Helpers.swift` file in `Rewrites/` that's not a single-rule helper — it's infrastructure and stays.
- 7 single-rule helper files remaining: `PreferFinalClasses`, `NoForceTry`, `ReflowComments`, `RedundantEscaping`, `WrapMultilineStatementBraces`, `NoForceUnwrap`, `NestedCallLayout`.
- Build clean (12 warnings baseline) at every step. Combined: 181 tests pass across the touched rules.



## Session 2 (continued, batch 5) — `PreferFinalClasses` + `ReflowComments` folded

- **`PreferFinalClasses`**: 155-line helpers + 32-line shell → single 155-line rule file. `PreferFinalClassesState` → nested `State`. `preferFinalClassesCollect` → `willEnter` body inline. `applyPreferFinalClasses` → `transform` body inline. All recursive helpers (`collectSubclassedNamesRecursive`, `commentMentionsSubclassing`, `convertOpenToPublic`, `replaceOpenModifier`, `openToPublic`) → `private static func` on the class. No external callers — entirely self-contained now.
- **`ReflowComments`**: 210-line helpers + 16-line shell → single 209-line rule file. `applyReflowComments` → `static func reflow(_:context:)`. All trivia helpers (`commentKind`, `commentText`, `makePiece`, `stripPrefix`, `isDirective`, `syntacticIndentColumn`, `indentationBefore`, `indentTrivia`) → `private static func`. Nested `CommentRunKind` enum stays. Updated 1 dispatcher caller in `TokenRewrites.swift`.

### Cumulative

- **8 of 13 helpers files folded.** 5 single-rule helpers remaining: `NoForceTry` (161), `RedundantEscaping` (242), `WrapMultilineStatementBraces` (369), `NoForceUnwrap` (641), `NestedCallLayout` (697).
- Build clean (12 warnings baseline) at every step. Combined this batch: 52 tests pass across the two folded rules.



## Session 2 (continued, batch 6) — `NoForceTry` folded

- **`NoForceTry`**: 161-line helpers + 60-line shell → single 175-line rule file. State class `NoForceTryState` → nested `State`. 12 free helper functions → `static func` on rule class. Updated 4 dispatcher callers in `Files/SourceFile.swift`, `Decls/{ImportDecl,FunctionDecl}.swift`, `Exprs/TryExpr.swift`. The `SourceFile.swift` dispatcher's `noForceTryVisitSourceFile(...)` collapsed to a direct `setImportsXCTest(context:sourceFile:)` call (the indirection was a single line of forwarding). `Self.diagnose` replaces `NoForceTry.diagnose`. Tests pass (15/15).

### Cumulative

- **9 of 13 helpers files folded.** 4 single-rule helpers remaining: `RedundantEscaping` (242), `WrapMultilineStatementBraces` (369), `NoForceUnwrap` (641), `NestedCallLayout` (697).
- Build clean (12 warnings baseline) at every step.



## Session 2 (continued, batch 7) — final 4 helpers folded; ALL 13 done

Final batch — completes the helper-fold sub-task.

- **`RedundantEscaping`** (242-line helpers + 17-line shell → 246-line single rule file): stateless. `applyRedundantEscaping` overloads inlined into `transform` overloads. All free helpers (`rewriteParameterClause`, `escapingAttribute`, `hasAttribute`, `attributeName`, `isInsideProtocol`) → `private static func`. `EscapeChecker` `SyntaxVisitor` stays at file scope as `private final class`. **Verified**: 7 tests pass.
- **`WrapMultilineStatementBraces`** (369-line helpers + 109-line shell → 411-line single rule file): stateless, 15 `transform` overloads. Each `apply*` overload inlined into the matching `transform`; shared helpers `wrappedBrace`/`stripTrailingOnLastSigToken`/`lineIndentation`/`stripBeforeBrace` → `private static func`. `TokenStripper` `SyntaxRewriter` stays at file scope. **Verified**: 18 tests pass.
- **`NoForceUnwrap`** (641-line helpers + 107-line shell → 612-line single rule file): largest stateful rule. `NoForceUnwrapState` → nested `State`, `NoForceUnwrapChainTopContext` → nested `ChainTopContext`. ~30 free helper functions → `static func`/`private static func` on the rule class. Updated 8 external dispatcher callers in `Rewrites/Decls/{FunctionDecl,ImportDecl}.swift`, `Rewrites/Files/SourceFile.swift`, `Rewrites/Exprs/{MemberAccessExpr,SubscriptCallExpr,ForceUnwrapExpr,FunctionCallExpr,AsExpr}.swift` (e.g., `noForceUnwrapRewriteForceUnwrap(...)` → `NoForceUnwrap.rewriteForceUnwrap(...)`). **Verified**: 28 tests pass.
- **`NestedCallLayout`** (697-line helpers + 85-line shell → 540-line single rule file): largest stateless rule. `NestedCallLevel` → nested `Level`. `nestedCallLayoutIndentUnit` → `private static let indentUnit`. ~20 free helper functions → `private static func`. `IndentShiftRewriter` and the `Trivia.shiftingNestedCallIndentation` extension stay at file scope (not strictly tied to the rule). The `NestedCallLayoutConfiguration` struct stays at file scope (it's a public-ish package type referenced from the configuration registry). **Verified**: 23 tests pass.

### Cumulative — fold sub-task complete

**13 of 13 helper files folded.** `Sources/SwiftiomaticKit/Rewrites/RewriteHelpers.swift` is the only `*Helpers.swift` file in `Rewrites/` and it's `applyRule` infrastructure (next on the cleanup list).

Status going into next session:
- All 13 single-rule helpers files: gone, folded into rule classes.
- `CompactStageOneRewriter+Generated.swift` → hand-written.
- `CompactStageOneRewriterGenerator` deleted; `RuleCollector` ~70 lines smaller.
- Build clean (12 warnings baseline) at every step. 76 tests across the four newly-folded rules pass.

### Remaining work (next sessions)

1. **Drop `applyRule` ladders** in dispatchers — replace `if context.shouldFormat(R.self, ...) { applyRule(R.self, to: &result, ..., transform: R.transform) }` with direct calls (or category-string gating). Then delete `applyRule` from `RewriteHelpers.swift`.
2. **Replace `Context.ruleState(for:)` (metatype-keyed)** with typed state properties on `Context`.
3. **Migrate structural-pass rules** off `RewriteSyntaxRule<V>` to plain `SyntaxRewriter` subclasses, then delete `RewriteSyntaxRule` itself.
4. **Stale doc-comment cleanup**: ~34 `Rewrites/<Group>/<NodeType>.swift` files reference `CompactStageOneRewriterGenerator.manuallyHandledNodeTypes` (gone). Cosmetic mass-edit.
5. **Reformat `CompactStageOneRewriter.swift`** from 2-space → 4-space indent (hand-written file inherited the generator's style).



## Session 2 (continued, batch 8) — stale doc-comment cleanup

Stripped all references to the deleted `CompactStageOneRewriterGenerator.manuallyHandledNodeTypes` from dispatcher headers — 34 files total.

- 19 `Rewrites/Exprs/<NodeType>.swift` (Phase 4e variant): removed the 4-line `///\n/// Per Phase 4e of `ddi-wtv` (sub-issue `mn8-do3`)…` block.
- 14 `Rewrites/Stmts/<NodeType>.swift` + `Rewrites/Decls/ImportDecl.swift` (Phase 4d / 4c variants): removed the same 4-line block (regex-matched across phase suffixes).
- 1 `Rewrites/Files/SourceFile.swift`: removed the 6-line longer-form note manually (it referenced `RewriteSyntaxRule.visit(_ SourceFileSyntax)` overrides and the generator path).

Verification: `xc-swift swift_diagnostics --no-include-lint` clean (12 warnings baseline). Test suite pass except for the 2 pre-existing pretty-printer-idempotency failures (`breaksElseWhenInlineBodyExceedsLineLength`, `optionalBindingConditions`) noted in earlier sessions — unrelated to this work.

`grep -r CompactStageOneRewriterGenerator Sources/` returns 0 results — all stale references gone.

### Remaining work (next sessions)

1. **Drop `applyRule` ladders** — see Stage 4 in earlier sessions.
2. **Replace `Context.ruleState(for:)` (metatype-keyed)** with typed state on `Context`.
3. **Migrate structural-pass rules** off `RewriteSyntaxRule<V>` to plain `SyntaxRewriter` subclasses, then delete `RewriteSyntaxRule`.
4. **Reformat `CompactStageOneRewriter.swift`** from 2-space → 4-space indent for consistency.



## Summary of Changes

Original goal — collapse compact-pipeline rule shells, eliminate the generator path, kill discoverability machinery the closed rule set no longer needs — shipped across this issue's sessions:

- **All 13 `*Helpers.swift` files folded** back into their rule classes. `Sources/SwiftiomaticKit/Rewrites/RewriteHelpers.swift` is the only `*Helpers.swift` left in `Rewrites/` (infrastructure for `applyRule`).
- **`CompactStageOneRewriter` is now hand-written** (`Sources/SwiftiomaticKit/Rewrites/CompactStageOneRewriter.swift`); generator deleted.
- **`CompactStageOneRewriterGenerator` deleted** + removed from `GeneratePaths`, `Generator/main.swift`, and `GeneratePlugin`'s outputs (5 → 4 generated files).
- **`RuleCollector` ~70 lines smaller** — `nodeLocalTransforms`/`nodeLocalWillEnter`/`nodeLocalDidExit` collections + the per-rule transform/willEnter/didExit AST extraction path are gone.
- **34 dispatcher headers cleaned** of stale `CompactStageOneRewriterGenerator.manuallyHandledNodeTypes` doc comments.

Build clean (12-warning baseline) at every step. Test suite parity (2 pre-existing pretty-printer-idempotency failures unrelated to this work).

## Follow-ups

The original issue body listed several deeper cleanups that are independent of the goal above. Split into separate tasks under parent `iv7-r5g`:

- `6ji-ue3` — Drop `applyRule` ladders in compact-pipeline dispatchers; delete `applyRule`.
- `c6i-b47` — Replace metatype-keyed `Context.ruleState(for:)` with typed state properties (blocked-by `6ji-ue3`).
- `2uk-cll` — Migrate structural-pass rules off `RewriteSyntaxRule\<V\>`, delete the base class.

Cosmetic deferred: reformat `CompactStageOneRewriter.swift` from 2-space → 4-space indent.
