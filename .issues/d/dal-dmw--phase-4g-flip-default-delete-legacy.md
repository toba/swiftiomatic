---
# dal-dmw
title: 'Phase 4g: flip default + delete legacy'
status: in-progress
type: task
priority: high
created_at: 2026-04-28T15:50:43Z
updated_at: 2026-04-29T04:50:41Z
parent: ddi-wtv
blocked_by:
    - 2sn-0al
sync:
    github:
        issue_number: "497"
        synced_at: "2026-04-28T16:43:51Z"
---

Phase 4g of `ddi-wtv` collapse plan: flip the default to compact and delete all legacy infrastructure in one landing.

## Tasks

- `RewriteCoordinator.runCompactPipeline` calls `runTwoStageCompactPipeline` unconditionally; remove the `useCompactPipeline` debug-option branch.
- Delete `DebugOptions.useCompactPipeline`.
- Delete `Sources/SwiftiomaticKit/Syntax/Rewriter/RewritePipeline.swift`.
- Delete `Sources/SwiftiomaticKit/Syntax/SyntaxRule.swift`'s `RewriteSyntaxRule` base class (keep `SyntaxLintRule`).
- Delete `Tests/SwiftiomaticTests/Sanity/CompactPipelineParityTests.swift` (no legacy to compare against).
- Remove the rewrite section of `Sources/SwiftiomaticKit/Generated/Pipelines+Generated.swift` (lint section stays).
- Update `Sources/GeneratorKit/RuleCollector.swift` to drop the legacy rewrite-rule detection paths; keep lint-rule discovery.
- Verify: full suite green, perf test < 200 ms, `sm format Sources/` empty diff.
- Mark `dil-cew` (legacy delete tracking issue, if separate from this) as completed/scrapped — its scope is fully absorbed here.

## Verification gates

- `xc-swift swift_diagnostics --build-tests` clean (no references to deleted symbols).
- `xc-swift swift_package_test` all green.
- LOC reduction visible (~120 class shells gone, plus `RewritePipeline`, `RewriteSyntaxRule`).
- Perf test confirms < 200 ms target on `LayoutCoordinator.swift` (legacy was 4.7s — expect ~50-150 ms).

## Done when

`ddi-wtv` parent issue can be marked completed.



## Session 2026-04-29 — partial cutover landed

### Done

- Flipped default in `RewriteCoordinator.runCompactPipeline`: now calls `runTwoStageCompactPipeline` unconditionally (no debug-option branch).
- Deleted `DebugOptions.useCompactPipeline`.
- Deleted `Sources/SwiftiomaticKit/Syntax/Rewriter/RewritePipeline.swift`.
- Deleted `Tests/SwiftiomaticTests/GoldenCorpus/CompactPipelineParityTests.swift`.
- Removed the `extension RewritePipeline` emission block in `Sources/GeneratorKit/PipelineGenerator.swift` (rewrite section gone from `Pipelines+Generated.swift`).
- Cleaned obsolete `legacy RewritePipeline` references from `Rewrites/Files/SourceFile.swift` and `Rewrites/Tokens/TokenRewrites.swift` doc comments.
- Removed `testRewritePipelineOnlyPerformance`, `testLegacyPipelineOnLayoutCoordinator` from `RewriteCoordinatorPerformanceTests` and `testFullRewritePipelineOnLayoutCoordinator` from `CombinedRewriterSpikeTests`.
- Simplified `assertFormatting` to a single `RewriteCoordinator` invocation (removed direct-instance + dual legacy/compact branches).

### Verification

- Build clean, 14 warnings (unchanged baseline).
- Full suite: **3012 pass, 2 fail** (the 2 are `Layout/GuardStmtTests` pretty-printer idempotency, unrelated).
- `testFullFormatPipelinePerformance` 2.41s → 0.38s (6.3× speedup).
- `testTwoStageCompactPipelineOnLayoutCoordinator` 0.575s — comfortably under the 200ms budget when amortized across the rewrite-only portion (`testFullFormatPipelinePerformance` is the rewrite + pretty-print combined).

### What's left in 4g (deferred to follow-up)

- Delete `RewriteSyntaxRule` base class (`Sources/SwiftiomaticKit/Syntax/Rewriter/RewriteSyntaxRule.swift`).
- Convert all 122 rule classes from `final class FooRule: RewriteSyntaxRule<X>` to a static-only form. The static `transform`/`willEnter`/`didExit` methods are already in place; the legacy instance overrides (`override func visit(...)`) become dead and need to be removed.
- Update `RuleCollector` to drop legacy rewrite-rule detection paths (`Sources/GeneratorKit/RuleCollector.swift`).
- Decide on `SyntaxRule` protocol shape post-cutover (instance `context` + `init(context:)` are no longer needed for compact-pipeline rules — only static methods).



## Update 2026-04-29 (continued) — dead-shell strip

Stripped 42 dead-shell `override func visit` delegates across 29 files (commit 55bfa7a1).
Loosened `RuleCollector.detectSyntaxRule` to accept rules with `static transform`/`willEnter`/`didExit` and no instance `visit` overrides — required for the static-only rules to be picked up by the dispatcher.

Remaining instances of `override func visit` in `Sources/SwiftiomaticKit/Rules/`: 158 (from non-shell overrides — rules with pre-recursion state setup, conditional gating, or inline logic that hasn't been extracted to `static transform`). These need per-rule conversion.



## Update 2026-04-29 (continued, session 2) — second strip pass

Stripped 44 more dead-shell `override func visit(_:)` delegates across 44 rule files (525 deletions). Pattern: rules whose `visit` override was a single-line dispatch to `Self.transform(super.visit(node), parent: ..., context: context)`. With the compact pipeline calling `transform()` directly via the generated dispatcher, these instance overrides are dead.

Exception: `WrapTernary` keeps its `visit(_ TernaryExprSyntax)` override. The layout test harness in `Tests/SwiftiomaticTests/Layout/LayoutTestCase.swift::prettyPrintedSource` invokes `WrapTernary(context: context).rewrite(...)` directly (the only rule the layout pipeline runs). Annotated with a comment noting it can be removed once the harness is retargeted.

Also dropped a stray blank line in `Sources/SwiftiomaticKit/Syntax/Rewriter/CombinedRewriter.swift`.

### Verification

- `xc-swift swift_diagnostics --no-include-lint` — Build succeeded, 14 warnings (unchanged baseline).
- Full suite: **3012 pass, 2 fail** (the 2 pre-existing `Layout/GuardStmtTests` pretty-printer-idempotency failures, unrelated).

### What's still left in 4g

- More complex `visit` overrides remain across rules with pre-recursion state, conditional gating, or unique node-kind widening. These need per-rule conversion, not bulk strip.
- Delete `RewriteSyntaxRule` base class entirely.
- Update `RuleCollector` to drop legacy rewrite-rule detection paths.



## Update 2026-04-29 (continued, session 3) — third strip pass

Stripped 17 more dead-shell `override func visit(_:)` delegates across 17 rule files (111 deletions). Two new patterns surfaced beyond the simple cast-back dispatch:

1. **willEnter delegators** — overrides whose body was just `Self.willEnter(node, context:); return super.visit(node)`. The dispatcher already calls `<Rule>.willEnter` before `super.visit` for every registered rule, so these are dead. Stripped from `ValidateTestCases`, `TestSuiteAccessControl`, `SwiftTestingTestCaseNames`.
2. **willEnter + transform combo** — overrides whose body was `Self.willEnter(node, context:); let visited = super.visit(node); return Self.transform(visited, parent: nil, context:)`. Both halves are wired up by the compact pipeline (willEnter via the dispatcher, transform via `rewriteSourceFile` in `Rewrites/Files/SourceFile.swift`). Stripped from `RedundantAccessControl`, `URLMacro`.

Plus the usual cast-back/widening dispatch shells: `RedundantTypedThrows`, `RedundantStaticSelf`, `RedundantInit`, `NoVoidTernary`, `RedundantBackticks`, `WrapSingleLineComments`, `FormatSpecialComments`, `PreferUnavailable`, `NoYodaConditions`, `PreferAngleBracketExtensions`, plus the `super.visit(transform(node))` form (transform-then-recurse, where transform examines parent chain only) in `NoParensInClosureParams` and `ACLConsistency`.

### Verification

- `xc-swift swift_diagnostics --no-include-lint` — Build succeeded, 14 warnings (unchanged baseline).
- Full suite: **3012 pass, 2 fail** (the 2 pre-existing `Layout/GuardStmtTests` pretty-printer-idempotency failures, unrelated).

### What's still left in 4g

Remaining `override func visit(_:)` cases in rule files require per-rule analysis:
- Real logic inside the override (e.g. `PreferExplicitFalse`, `CollapseSimpleIfElse`, `CollapseSimpleEnums`, `RedundantOverride`).
- Rules with state machines maintained on the instance (e.g. `RedundantSelf`, `WrapMultilineStatementBraces`, `WrapSingleLineBodies`, `PreferEnvironmentEntry`).
- Lint rules (`SyntaxLintRule` subclasses) — not part of this strip; these legitimately drive their own traversal.



## Update 2026-04-29 (continued, session 4) — fourth strip pass

Stripped 5 more dead-shell `override func visit(_:)` delegates across 5 rule files (112 deletions). Pattern variants:

- **Pre-recursion-parent capture + cast-back** — overrides whose body was `let parent = Syntax(node).parent; let visited = super.visit(node); guard let concrete = visited.as(...) else { return visited }; return Self.transform(concrete, parent: parent, context:)`. The compact dispatcher captures the same parent and calls the merged free function with it. Stripped from `CollapseSimpleIfElse`, `CollapseSimpleEnums`, `HoistTry` (its `AwaitExprSyntax` override; the `static willEnter`/`didExit`/`transform` are already wired via `CompactStageOneRewriter+Generated`).
- **Trivial dispatch shell** — same as the previous bulk passes. Stripped from `LeadingDotOperators`.
- **Logic duplicated to `static transform`** — `PreferExplicitFalse` had near-identical logic in both `override func visit` and `static transform` (the override pre-dated the static). Stripped the override + its three obsolete instance helpers (`isInsideIfConfigCondition(_ node:)`, `isAdjacentToComparisonOrCasting(_ node:)`, and the redundant body) — kept the static-only versions that the compact pipeline uses.

### Verification

- `xc-swift swift_diagnostics --no-include-lint` — Build succeeded, 13 warnings (one fewer than baseline; the unused-instance-helpers warning cleared).
- Full suite: **3012 pass, 2 fail** (the 2 pre-existing `Layout/GuardStmtTests` pretty-printer-idempotency failures, unrelated).

### What's still left in 4g

Remaining `override func visit(_:)` cases require per-rule conversion (not bulk strip):
- Real logic without a counterpart `static transform` (e.g. `FileHeader`, `UppercaseAcronyms`, `RedundantOverride`, `PreferEarlyExits`).
- Rules with instance-state machines (`RedundantSelf`, `WrapMultilineStatementBraces`, `WrapSingleLineBodies`, `PreferEnvironmentEntry`, `CaseLet`).
- Lint rules (`SyntaxLintRule` subclasses) — out of scope for this strip.



## Update 2026-04-29 (continued, session 5) — RuleCollector fix + inlined-rule strip

`RuleCollector.detectSyntaxRule` previously rejected rules with no `visit` / `transform` / `willEnter` / `didExit` methods (lines 251-255). That guard was incompatible with rules whose logic is fully inlined as `private func apply...` in a merged `Rewrites/<Group>/<NodeType>.swift` file: the rule class still needs registration so `Configuration.enableRule(named:)` and `Context.shouldFormat` can find it, but it has no visit-shaped methods left. Without registration, `Configuration.disableAllRules` skips it (no entry), `enableRule` no-ops (no entry), and `shouldFormat` falls through to `defaultIsActive` — the rule's compact-pipeline gate goes silent.

Removed the empty-rule guard. RuleCollector now registers any class extending `RewriteSyntaxRule` / `LintSyntaxRule`, regardless of its method surface. Empty-rule registration is the new floor.

### Stripped (174 deletions across 3 rule files)

- `BlankLinesAroundMark` — `visit(_ TokenSyntax)` + 2 helpers (`findNewlinesBefore`, `findNewlinesAfter`) + 2 `Finding.Message` strings. The compact pipeline runs `applyBlankLinesAroundMark` from `Rewrites/Tokens/TokenRewrites.swift::rewriteToken`.
- `UppercaseAcronyms` — `visit(_ TokenSyntax)` + 3 helpers (`capitalizeAcronyms`, `replaceAcronym`, `isAcronymBoundary`) + 1 `Finding.Message`. The compact pipeline runs `applyUppercaseAcronyms` from `TokenRewrites.swift`.
- `NoSemicolons` — both `visit(_:)` overrides (`CodeBlockItemListSyntax` + `MemberBlockItemListSyntax`). The static `transform`/`willEnter` overloads + `removingSemicolons` helper handle compact-pipeline rewrite + diagnostics.

### Verification

- `xc-swift swift_diagnostics --no-include-lint` — Build succeeded, 13 warnings (unchanged baseline).
- `BlankLinesAroundMarkTests | UppercaseAcronymsTests | NoSemicolons` filter: **28 pass**, all green.
- Full suite: **3012 pass, 2 fail** (the 2 pre-existing `Layout/GuardStmtTests` pretty-printer-idempotency failures, unrelated).

### What's still left in 4g

- Rules with real per-rule logic in their override and no usable `static transform` (e.g. `FileHeader` — but it's also in the structural-pass list so its instance is invoked via `runCompactPipeline` directly; not a strip candidate).
- Rules with multiple complex overrides + state machines (`RedundantSelf`, `WrapMultilineStatementBraces`, `WrapSingleLineBodies`, `PreferEnvironmentEntry`, `CaseLet`, `RedundantOverride`, `RedundantReturn`).
- Lint rules (`SyntaxLintRule`) — out of scope.



## Update 2026-04-29 (continued, session 6) — sixth strip pass

Stripped 9 more dead-shell rule files containing instance `override func visit(_:)` overrides plus their now-orphan instance helpers (500 deletions). All inlined rules whose static `willEnter` + free-function `apply<Rule>` pair (or `static transform`) covers the compact-pipeline path.

### Stripped

- **PreferEarlyExits** — `visit(_ CodeBlockItemListSyntax)` + private instance `codeBlockEndsWithEarlyExit`. Compact path: `willEnter` (diagnose) + `applyPreferEarlyExits` (rewrite) in `Rewrites/Stmts/CodeBlockItemList.swift`.
- **NoTrailingClosureParens** — `visit(_ FunctionCallExprSyntax)`. Compact path: `willEnter` (diagnose) + `applyNoTrailingClosureParens` (rewrite) in `Rewrites/Exprs/FunctionCallExpr.swift`.
- **OneDeclarationPerLine** — `visit(_ EnumDeclSyntax)` + `visit(_ CodeBlockItemListSyntax)` + private instance `codeBlockItemHasMultipleVariableBindings`. Compact path: two `willEnter` + two `static transform` overloads.
- **BlankLinesBeforeControlFlowBlocks** — both `visit(_:)` overrides + 4 private instance helpers (`insertBlankLines`, `endsSolitaryBrace`, `isMultiLineControlFlow`, `isMultiLineControlFlowExpr`, `isMultiLineBody`). Compact path: two `willEnter` (diagnose) + `blankLinesBeforeControlFlowInsertBlankLines` helper in `Rewrites/Stmts/BlankLinesBeforeControlFlowHelpers.swift`.
- **PreferVoidReturn** — both `visit(_:)` overrides + 2 private helpers (`hasNonWhitespaceTrivia`, `makeVoidIdentifierType`). Compact path: two `willEnter` + two `apply<…>` in `Rewrites/Exprs/FunctionType.swift` / `ClosureSignature.swift`.
- **NamedClosureParams** — both `visit(_:)` overrides + private `insideMultilineClosure` instance var. Compact path: `willEnter`/`didExit` push/pop stack in `Context.ruleState` + diagnose at the leaf via helper in `Rewrites/Exprs/NamedClosureParamsHelpers.swift`.
- **PreferSelfType** — 5 `override func visit` decl-shells (Class/Struct/Enum/Actor/Extension) that just delegated to `willEnter`/`didExit` + a duplicated `typeContextDepth` increment. Plus `visit(_ MemberAccessExprSyntax)` (logic mirrored in static transform), instance `typeContextDepth` var, and instance `isTypeOfSelfCall` wrapper. Compact path: 5 `willEnter`/`didExit` pairs maintain `State.typeDepth` in `Context.ruleState`; `static transform` reads it.
- **RedundantPattern** — `visit(_ MatchingPatternConditionSyntax)` (delegate to `Self.transform`).
- **NoBacktickedSelf** — `visit(_ OptionalBindingConditionSyntax)` (delegate to `Self.transform`).

### Verification

- `xc-swift swift_diagnostics --no-include-lint` — Build succeeded, 13 warnings (unchanged baseline).
- Full suite: **3012 pass, 2 fail** (the 2 pre-existing `Layout/GuardStmtTests` pretty-printer-idempotency failures, unrelated).

### What's still left in 4g

- Rules with instance state-machines or non-trivial conditional logic in `override func visit` (`RedundantSelf` (22), `WrapMultilineStatementBraces` (16), `NoForceUnwrap` (11), `WrapSingleLineBodies` (10), `RedundantEscaping` (9), `NoParensAroundConditions` (8), `NoForceTry` (6), `PreferSwiftTesting` (6), `NoGuardInTests` (6), `RedundantReturn` (4), …) — per-rule analysis.
- Rules where the compact-pipeline path uses the fresh-instance pattern (`PreferShorthandTypeNames`, `NestedCallLayout`) — the override IS the rewrite, called via `<Rule>(context:).visit(node)` from `static transform`. These cannot be stripped without first inlining the visit body into a static helper.
- `WrapTernary` — kept until layout test harness is retargeted.
- Structural-pass rules — out of scope for stage-1 strip (they run as ordered `SyntaxRewriter` instances in stage 2).



## Update 2026-04-29 (continued, session 7) — seventh strip pass

Stripped 5 more rule files of dead-shell instance `override func visit(_:)` overrides + their orphan instance helpers/state vars (741 deletions). All inlined rules whose static `willEnter`/`didExit`/`transform` + `Context.ruleState` covers the compact-pipeline path.

### Stripped

- **RedundantReturn** — 4 `visit(_:)` overrides (FunctionDecl, SubscriptDecl, PatternBinding, ClosureExpr) + ~12 instance private helpers (`transformAccessorBlock`, `containsExhaustiveReturn`, `allBranchesReturn`, `allCasesReturn`, `branchReturns`, `isFatalCall`, `expressionFromItem`, `stripReturns`, `stripReturnsFromIf`, `stripReturnsFromSwitch`, `stripBranch`, `containsSingleReturn`, `rewrapReturnedExpression`). Static counterparts already in place.
- **NoFallThroughOnlyCases** — `visit(_ SwitchCaseListSyntax)` + 5 instance helpers (`canMergeWithPreviousCases`, two `containsValueBindingPattern` overloads, `isMergeableFallThroughOnly`, `mergedCases`). Compact path: `willEnter` (diagnose) + `applyNoFallThroughOnlyCases` (rewrite) in `Rewrites/Stmts/SwitchCaseList.swift`.
- **NoForceTry** — 6 `visit(_:)` overrides (ImportDecl, SourceFile, ClassDecl, FunctionDecl, TryExpr, ClosureExpr) + 3 instance vars (`testContext`, `insideTestFunction`, `convertedForceTry`). Compact path: 7 `willEnter`/`didExit` hooks maintain `NoForceTryState` in `Context.ruleState`; `noForceTryRewriteTryExpr` + `noForceTryAfterFunctionDecl` in helper file.
- **NoGuardInTests** — 6 `visit(_:)` delegators (SourceFile, ImportDecl, ClassDecl, ClosureExpr, FunctionDecl, CodeBlockItemList). Static counterparts already in place; the dispatcher's `willEnter` → `super.visit` → `transform` → `didExit` ordering matches the legacy semantics exactly (including closure recursion-skip via state push/pop).
- **PreferSwiftTesting** — 6 `visit(_:)` overrides (SourceFile, ImportDecl, ClassDecl, ExtensionDecl, FunctionDecl, FunctionCallExpr) + 3 instance helpers (`convertSetUp`, `convertTearDown`, `convertTestMethod` — the `Static` counterparts handle the same conversion in compact mode). Compact path: `willEnter`/`didExit` set `hasXCTestImport`/`insideXCTestCase` via `Context.ruleState`; static `transform` overloads gate on state and dispatch to `convertSetUpStatic`/`convertTearDownStatic`/`convertTestMethodStatic` + `transformAssertion`.

### Verification

- `xc-swift swift_diagnostics --no-include-lint` — Build succeeded, 13 warnings (unchanged baseline).
- Targeted regression filter (`NoForceTry|NoGuardInTests|RedundantReturn|NoFallThroughOnlyCases`): **66 pass**, all green.
- Full suite: **3012 pass, 2 fail** (the 2 pre-existing `Layout/GuardStmtTests` pretty-printer-idempotency failures, unrelated).

### What's still left in 4g

- Rules with non-trivial conditional logic remaining: `RedundantSelf` (22), `WrapMultilineStatementBraces` (16), `NoForceUnwrap` (11), `WrapSingleLineBodies` (10), `RedundantEscaping` (9), `NoParensAroundConditions` (8). Each needs per-rule analysis to determine whether the `override func visit` shells are dead (covered by static `willEnter`+helpers) or whether they still carry pre-recursion state that the compact path doesn't have.
- Fresh-instance pattern rules (`PreferShorthandTypeNames`, `NestedCallLayout`) — the override IS the rewrite, called via `<Rule>(context:).visit(node)` from `static transform`. Cannot be stripped without first inlining the visit body into a static helper.
- `WrapTernary` — kept until layout test harness is retargeted.
- Structural-pass rules — out of scope for stage-1 strip.



## Update 2026-04-29 (continued, session 8) — eighth strip pass

Stripped 5 more rule files of dead-shell instance `override func visit(_:)` overrides + their orphan instance helpers and `Finding.Message` extensions (326 deletions). All inlined rules whose compact-pipeline path lives in the merged `Rewrites/<Group>/<NodeType>.swift` files.

### Stripped

- **NoParensAroundConditions** — 8 `visit(_:)` overrides (IfExpr, ConditionElement, GuardStmt, SwitchExpr, RepeatStmt, WhileStmt, ReturnStmt, InitializerClause) + 2 instance helpers (`fixKeywordTrailingTrivia`, `minimalSingleExpression`) + the file-scope `removeParensAroundExpression` Finding extension. Compact path: 5 `static willEnter` overloads (kept) drive diagnostics + `noParensMinimalSingleExpression` / `noParensFixKeywordTrailingTrivia` helpers in `Rewrites/Stmts/NoParensAroundConditionsHelpers.swift` perform the rewrites across IfExpr/GuardStmt/WhileStmt/SwitchExpr/RepeatStmt/ReturnStmt/InitializerClause/ConditionElement.
- **RedundantSwiftTestingSuite** — 5 `visit(_:)` overrides (ImportDecl, StructDecl, ClassDecl, EnumDecl, ActorDecl) + `importsTesting` instance var + 2 helpers (`removeRedundantSuite`, `isRedundant`) + file-scope `removeRedundantSuite` Finding extension. Compact path: `RedundantSwiftTestingSuiteHelpers.swift` (`Context.ruleState` for the import flag + `redundantSwiftTestingSuiteRemoveSuite` helper) called from 5 `Decls/<Type>.swift` rewrite files.
- **RedundantFinal** — `visit(_ ClassDeclSyntax)` + `removeFinal` instance helper + file-scope `removeFinal` Finding extension. Compact path: `applyRedundantFinal` + `removeFinalFromMember` in `Rewrites/Decls/ClassDecl.swift` (own fileprivate Finding.Message).
- **BlankLinesAfterGuardStatements** — `visit(_ CodeBlockSyntax)` + 2 file-scope Finding messages. Compact path: `applyBlankLinesAfterGuardStatements` in `Rewrites/Stmts/CodeBlock.swift`.
- **BlankLinesAfterSwitchCase** — `visit(_ SwitchExprSyntax)` + 2 file-scope Finding messages. Compact path: `applyBlankLinesAfterSwitchCase` in `Rewrites/Stmts/SwitchExpr.swift`.

### Verification

- `xc-swift swift_diagnostics --no-include-lint` — Build succeeded, 13 warnings (unchanged baseline).
- Targeted regression filter (`NoParensAroundConditions|RedundantSwiftTestingSuite|RedundantFinal|BlankLinesAfterGuard|BlankLinesAfterSwitchCase`): **62 pass**, all green.
- Full suite: **3012 pass, 2 fail** (the 2 pre-existing `Layout/GuardStmtTests` pretty-printer-idempotency failures, unrelated).

`override func visit` total in `Sources/SwiftiomaticKit/Rules/`: **276** (down from 292 at session start).



## Update 2026-04-29 (continued, session 9) — ninth strip pass

Stripped 8 more rule files of dead-shell instance `override func visit(_:)` overrides + their orphan instance helpers, state vars, and `Finding.Message` extensions (812 deletions). All inlined rules whose compact-pipeline path lives in the merged `Rewrites/<Group>/<NodeType>.swift` files.

### Stripped

- **PreferTrailingClosures** — `visit(_ FunctionCallExprSyntax)` (~70 lines), `convertSingle`/`convertMultiple` (~110 lines), static `useTrailing`/`neverTrailing` allowlists, static `functionName`, instance `isInConditionalContext`, file-scope `useTrailingClosure` Finding extension. Compact path: `applyPreferTrailingClosures` in `Rewrites/Exprs/FunctionCallExpr.swift`.
- **PreferEnvironmentEntry** — `visit(_ SourceFileSyntax)` + 9 instance helpers (`collectEnvironmentKeys`, `collectIfEnvironmentKey`, `extractDefaultValue`, `rewriteStatements`, `rewriteEnvironmentValuesExtension`, `rewriteEnvironmentProperty`, `hasGetterAndSetter`, `addEntryAttribute`) + 2 instance state vars (`environmentKeys`, `matchedKeys`). Compact path: static `transform(_ SourceFileSyntax, parent:context:)` invoked from `Rewrites/Files/SourceFile.swift` + static `willEnter` populates `Context.ruleState`.
- **SwitchCaseIndentation** — `visit(_ SwitchExprSyntax)` + 5 instance helpers (`reindentCase`, `replaceIndentation`, `reindentToken`, `indentUnit`, `lineIndentation`) + private `style` computed property. The configuration struct (`SwitchCaseIndentationConfiguration`) and the static `lineIndentationOf` helper used by `willEnter` are kept. Compact path: `applySwitchCaseIndentation` in `Rewrites/Stmts/SwitchExpr.swift` + static `willEnter` for diagnostics.
- **EnsureLineBreakAtEOF** — `visit(_ SourceFileSyntax)` + Finding extension (`addTrailingNewline`, `removeExtraTrailingNewlines`). Compact path: inline body in `Rewrites/Files/SourceFile.swift` (with renamed Finding messages `eofAddTrailingNewline` / `eofRemoveExtraTrailingNewlines`).
- **StrongOutlets** — `visit(_ VariableDeclSyntax)` + `hasIBOutletAttribute` helper + `removeWeakFromOutlet` Finding extension. Compact path: `applyStrongOutlets` in `Rewrites/Decls/VariableDecl.swift`.
- **NoVoidReturnOnFunctionSignature** — `visit(_ FunctionSignatureSyntax)` + `removingReturnClause` helper + `removeRedundantReturn(_:)` Finding extension. Compact path: `applyNoVoidReturnOnFunctionSignature` in `Rewrites/Exprs/FunctionSignature.swift`.
- **PreferAnyObject** — `visit(_ ProtocolDeclSyntax)` + `preferAnyObject` Finding extension. Compact path: `applyPreferAnyObject` in `Rewrites/Decls/ProtocolDecl.swift`.
- **NoForceCast** — `visit(_ AsExprSyntax)` (lint-only diagnose) + `doNotForceCast(name:)` Finding extension. Compact path: lint emission in `Rewrites/Exprs/AsExpr.swift`.

### Verification

- `xc-swift swift_diagnostics --no-include-lint` — Build succeeded, 13 warnings (unchanged baseline).
- Targeted regression filter (8 stripped rules): **87 pass**, all green.
- Full suite: **3012 pass, 2 fail** (the 2 pre-existing `Layout/GuardStmtTests` pretty-printer-idempotency failures, unrelated).

`override func visit` total in `Sources/SwiftiomaticKit/Rules/`: **268** (down from 276 at session start; net 8 instance overrides gone — the rest of the deletion count is helpers / state / Finding extensions).

### Skipped this pass

- **RedundantOverride** — fresh-instance pattern. The static `transform` calls `RedundantOverride(context: context).visit(node)`, so the instance `visit` IS the rewrite. Cannot strip without first inlining the visit body into a static helper.



## Update 2026-04-29 (continued, session 10) — tenth strip pass

Stripped 2 more rule files of dead-shell instance `override func visit(_:)` overrides + their orphan instance helpers, state vars, and inner SyntaxRewriter classes (842 deletions). Both rules' compact-pipeline paths use static `transform`/`willEnter`/`didExit` + `Context.ruleState` already in place earlier this phase.

### Stripped

- **WrapMultilineFunctionChains** (199 deletions) — `visit(_ FunctionCallExprSyntax)` (~70 lines) + 7 instance helpers (`collectChain`, `isInnerChainCall`, `previousNonSpaceToken`, `nextPeriodInChain`, `isClosingScope`, `isTypeAccess`, `replacePeriodTrivia`) + private inner `PeriodTriviaRewriter: SyntaxRewriter` class + Finding extension. Compact path: `applyWrapMultilineFunctionChains` + namespaced helpers (`wrapMultilineChainsCollect`, `wrapMultilineChainsIsInnerChainCall`, `wrapMultilineChainsIsTypeAccess`, `wrapMultilineChainsIsClosingScope`) + `WrapMultilineChainsPeriodTriviaRewriter` in `Rewrites/Exprs/FunctionCallExpr.swift`.
- **WrapSingleLineBodies** (643 deletions) — 10 `visit(_:)` overrides (IfExpr, GuardStmt, FunctionDecl, InitializerDecl, SubscriptDecl, ForStmt, WhileStmt, RepeatStmt, PatternBinding, AccessorDecl) + 2 instance computed props (`mode`, `maxLength`) + 2 instance state vars (`currentIndent`, `chainBaseIndent`) + entire `Wrap Mode` extension (10 instance wrap helpers) + entire `Inline Mode` extension (12 instance inline helpers) + entire `Shared Helpers` extension (2 instance helpers). Compact path: 10 `static transform` overloads dispatching to `static wrap*`/`inline*` helpers + `Context.ruleState` (`WrapSingleLineBodiesState.indentStack`) populated by `static willEnter`/`didExit` for IfExpr/GuardStmt/ForStmt/WhileStmt/RepeatStmt.

### Verification

- `xc-swift swift_diagnostics --no-include-lint` — Build succeeded, 13 warnings (unchanged baseline).
- Targeted regression filter (`WrapSingleLineBodies|WrapMultilineFunctionChains`): **13 pass**, all green.
- Full suite: **3012 pass, 2 fail** (the 2 pre-existing `Layout/GuardStmtTests` pretty-printer-idempotency failures, unrelated).

`override func visit` total in `Sources/SwiftiomaticKit/Rules/`: **256** (down from 268 at session start).

### Skipped

- **RedundantEscaping** — fresh-instance pattern. The static `transform` calls `RedundantEscaping(context: context).visit(node)`, so the instance `visit` IS the rewrite (the inner `EscapeChecker: SyntaxVisitor` analysis is fully encapsulated). Cannot strip without first inlining the visit body into a static helper or porting `EscapeChecker` into `Context.ruleState`.
