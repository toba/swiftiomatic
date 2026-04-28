---
# ddi-wtv
title: Cut over to `compact` pipeline; delete superseded rule files
status: in-progress
type: feature
priority: high
created_at: 2026-04-28T01:41:38Z
updated_at: 2026-04-28T17:51:57Z
parent: iv7-r5g
blocked_by:
    - eti-yt2
    - o72-vx7
    - e4v-075
sync:
    github:
        issue_number: "480"
        synced_at: "2026-04-28T17:53:15Z"
---

## Continuation Brief (for fresh sessions)

**Current state (2026-04-28, end of session):**

- ✅ Dispatch scaffold: `RewriteCoordinator.runCompactPipeline` exists; default still legacy.
- ✅ Generator emits `CompactStageOneRewriter+Generated.swift`.
- ✅ 3-arg `transform(_:parent:context:)` contract.
- ✅ Cluster 1 `vz0-31g`, Cluster 2 `5r3-peg`, Cluster 3 `r0w-l4r` — all completed.
- ✅ `g6t-gcm`: two-stage compact pipeline wired behind `DebugOptions.useCompactPipeline`. Default path still legacy.
- ✅ `fkt-mgf`: parity test green on 3-fixture corpus; perf ~5.9× speedup on `LayoutCoordinator.swift` (legacy 4.591s → two-stage 0.778s, debug).
- ⏳ `7fp-ghy` (in-progress): converting the 18 deferred rules so `dil-cew` becomes safe.
  - **Infrastructure done**: `Context.ruleState(for:initialize:)` (per-file rule-state cache, reference-typed) + generator emits `static func willEnter(_ T, context:)` / `didExit(_ T, context:)` hooks before/after `super.visit` in the combined rewriter.
  - **Batch 1 (trivial)**: 3 ported (`NoVoidTernary`, `NoAssignmentInExpressions`, `ProtocolAccessorOrder`). 4 over-simplified by Batch 1 agent and reverted from git after triage — re-port needed: `NoSemicolons`, `OneDeclarationPerLine`, `WrapSingleLineBodies`, `PreferExplicitFalse`. Bonus revert: `RedundantReturn` (broken in `r0w-l4r`, hidden until full suite ran).
  - **Batch 2 (moderate, Context.ruleState)**: all 8 ported and green. `LeadingDotOperators`, `URLMacro`, `RedundantAccessControl`, `TestSuiteAccessControl`, `SwiftTestingTestCaseNames`, `ValidateTestCases`, `NoGuardInTests`, `PreferSwiftTesting` — most use `willEnter` for file-level pre-scans and/or `willEnter`+`didExit` for class/extension/function scope tracking.
  - **Batch 3 (hard, scope hooks)**: not started. Three rules — `Idioms/PreferSelfType` (depth counter via willEnter/didExit), `Redundancies/RedundantSelf` (3 scope stacks), `Idioms/PreferEnvironmentEntry` (file-level pre-scan).
- ❌ `dil-cew` (flip default + delete legacy): blocked on `7fp-ghy`. Will become safe once Batch 3 lands and the 5 reverted rules get a careful re-port.

**Test status:** 3022 passed / 2 failed. Both failures are `GuardStmtTests` (`breaksElseWhenInlineBodyExceedsLineLength`, `optionalBindingConditions`) — pretty-printer idempotence, unrelated to any rule file in this work and predate the deferred-rule port. Parity test (`CompactPipelineParityTests`) stays green.

**Re-port pattern (for the 5 reverted rules)**: keep the original `override func visit` body verbatim — DO NOT simplify or remove manual `rewrite(Syntax(item))` / `super.visit` calls. Add `static func transform(_:parent:context:)` strictly alongside as a separate code path. The static transform CAN be simpler (combined rewriter handles descendant traversal), but the override must keep its full original logic so legacy unit tests stay green. Code duplication is the price of incremental migration.

**Test-coverage gap**: the 3-fixture `CompactPipelineParityTests` stayed green even while 50 rule-specific unit tests were broken — the corpus doesn't exercise enough patterns to catch divergences in `NoSemicolons`, `OneDeclarationPerLine`, `WrapSingleLineBodies`, `PreferExplicitFalse`, `RedundantReturn`, etc. When porting the remaining batches, ALWAYS run the full test suite (`xc-swift swift_package_test`) after each batch — not just the parity test.

**Key files:**

- `Sources/GeneratorKit/RuleCollector.swift` — detects 3-arg `transform` shape.
- `Sources/GeneratorKit/CompactStageOneRewriterGenerator.swift` — emits the combined rewriter.
- `Sources/SwiftiomaticKit/Syntax/Rewriter/RewriteCoordinator.swift` — dispatch site (`runCompactPipeline`).
- `Sources/SwiftiomaticKit/Syntax/SyntaxRule.swift` — static `Self.diagnose(_:on:context:)` helper.
- Generated output: `.build/plugins/outputs/swiftiomatic/SwiftiomaticKit/destination/GenerateCode/CompactStageOneRewriter+Generated.swift`

**Per-issue handoff briefs:** see `5r3-peg`, `r0w-l4r`, and `7fp-ghy` issue bodies — each has a self-contained Continuation Brief covering the signature contract, friction patterns, reference rules to copy from, and verification commands. The plan file at `~/.claude/plans/in-that-case-let-glittery-hopper.md` documents the Batch 1/2/3 strategy and the Context.ruleState + willEnter/didExit infrastructure design.

**Behavior is unchanged today:** the combined rewriter is generated but not wired in; ported rules continue running through legacy `RewritePipeline`. Tests must pass throughout cluster work.

---

## Goal

Replace `FormatPipeline` with the two-stage style-driven architecture from epic `iv7-r5g` and delete the now-orphaned `SyntaxFormatRule` files.

## Stages

1. **Combined `SyntaxRewriter`** — every node-local normalization the `compact` style requires, applied in a single tree walk (validated by spike `eti-yt2`).
2. **Structural passes** (≤3) — `SortImports`, blank-line policy, `ExtensionAccessLevel`-style cross-tree reshapers. Each is its own walk; cross-pass ordering kept explicit.
3. **Pretty-print** — unchanged, parameterised by the style.

## Tasks

- Delete `SyntaxFormatRule` files in the `deletable` bucket of inventory `kl0-8b8`.
- Move surviving rules' logic into the combined rewriter or one of the structural passes; delete the rule files once their logic is absorbed.
- Regenerate `Sources/SwiftiomaticKit/Generated/Pipelines+Generated.swift` — the lint section is unchanged, the rewrite section either disappears or shrinks to the structural passes.
- Update `Sources/Generator/` to reflect the new architecture if needed.
- Run the full lint + layout test suite. Run `Tests/SwiftiomaticPerformanceTests/RewriteCoordinatorPerformanceTests.swift` and confirm < 200 ms on `LayoutCoordinator.swift`.

## Verification

- `xc-swift swift_package_test` clean.
- `sm format Sources/SwiftiomaticKit/Layout/LayoutCoordinator.swift` finishes well under 200 ms.
- Diff of formatted output across the project is empty (or only contains intentional changes documented in the `compact` spec).



## Refinement: keep file organization

The combined stage-1 rewriter is a **thin dispatcher**, not a megafile. Each `visit(_:)` override delegates to a free function or extension method living in its own file under `Sources/SwiftiomaticKit/Rules/<Group>/<Aspect>.swift` — preserving today's discoverability. The directory layout under `Rules/` should look familiar after cutover; only the type-level wrapping (`SyntaxFormatRule` subclass + own `SyntaxRewriter` per rule) goes away. Performance stays the primary goal; file structure is a secondary nice-to-have.



## Execution Playbook (for follow-up session)

The spike (`eti-yt2`) confirmed ~900× headroom on the worst-case file. The blocking issue for an in-session cutover is **double-recursion**: today's rules subclass `SyntaxRewriter` and their `visit(_ T)` calls `super.visit(node)` first (recursing children), then applies single-node logic. A combined rewriter that simply chained each rule's `visit` per node would re-recurse children N times — worse than today.

### Required refactor (one-time, mechanical)

For each of the 122 node-local rules, extract the single-node logic into a static `transform` function:

```swift
// Before (today)
final class ACLConsistency: RewriteSyntaxRule<BasicRuleValue> {
    override func visit(_ node: DeclModifierSyntax) -> DeclModifierSyntax {
        let visited = super.visit(node)  // recurses
        // ... single-node logic
    }
}

// After
enum ACLConsistencyTransform {
    static func transform(
        _ node: DeclModifierSyntax,
        context: Context
    ) -> DeclModifierSyntax {
        // ... single-node logic only (no super.visit)
    }
}
```

### Cutover steps (in order)

1. **Generator extension** (`Sources/GeneratorKit/PipelineGenerator.swift`):
   - Collect node-type → [transform-fn] mapping for the 122 node-local rules (parallel to `syntaxNodeLinters`).
   - Emit a new `CompactStageOneRewriter+Generated.swift` whose `visit(_ T)` calls `super.visit(node)` once, then chains every rule's static `transform` for that node type.

2. **Rule refactor** (122 files): extract static `transform` functions. Mechanical; can be done rule-by-rule without breaking the existing pipeline (additive).

3. **Wire compact path** (`RewriteCoordinator`):
   - When `config[StyleSetting.self] == .compact`: run `CompactStageOneRewriter` (one walk), then the 13 structural passes from `kl0-8b8` in the order from `2kl-d04` §2.
   - Keep the legacy `RewritePipeline` as a fallback (initially gated on a debug flag, removed in a follow-up).

4. **Structural passes**: keep the 13 structural rules from `kl0-8b8` as ordered `SyntaxRewriter` subclasses. Order from `2kl-d04`: SortImports → BlankLinesAfterImports → FileScopedDeclarationPrivacy → ExtensionAccessLevel → PreferFinalClasses → ConvertRegularCommentToDocC → BlankLinesBetweenScopes → ConsistentSwitchCaseSpacing → SortDeclarations → SortSwitchCases → SortTypeAliases → FileHeader → ReflowComments.

5. **Delete** the 122 `RewriteSyntaxRule` subclass shells once their transform fns are absorbed and tests pass. Lint-side rules continue using the same files (some are dual lint+rewrite — split into separate types if needed).

6. **Regenerate** `schema.json`: `swift run Generator`.

7. **Verify**:
   - `xc-swift swift_package_test` clean.
   - `testCombinedRewriterOnLayoutCoordinator` perf < 200 ms (currently 5 ms with 3 rules; expect ~50–150 ms with all 122).
   - Diff `sm format` output across the project — should be empty or only intentional changes documented in `2kl-d04` §7.

### Risk mitigations

- **Same-node-type conflicts**: when multiple rules transform the same node type, order matters. The Generator should emit them in a deterministic order (alphabetical or explicit priority list per node type). Add a test for any known interactions.
- **Rule logic that reads parent**: a few node-local rules (e.g. `ACLConsistency` walking up to nominal parent) read `node.parent`. Within a single walk, the parent is the *original* tree's parent until `super.visit` returns — same constraint today's rules navigate. Should still work; flag during cutover if not.
- **Diagnostics**: today each rule's `diagnose()` calls go through `context`. The static `transform` functions need `context` passed in. Trivial.

### Estimated effort

- Generator extension + scaffolding: ~half day.
- Rule refactor (122 files, ~5 min each): ~2–3 days.
- Wire-up + structural pass ordering: ~half day.
- Test diff resolution: ~1 day.

Total: ~4–5 days of focused work.



## Collapse Plan (Option 1, 2026-04-28)

Supersedes the "Execution Playbook" above. Decision: collapse the per-rule `RewriteSyntaxRule` subclass shells *during* this issue rather than deferring to `dil-cew`. Removes the duplication friction surfaced in the 7fp-ghy triage note (re-port pattern was preserving override bodies *only* to keep legacy unit tests green).

### End state

- One `CompactStageOneRewriter` (generated) doing all node-local rewrites in a single walk.
- Per-rule logic lives as a free `static func transform(_:parent:context:)` in `Sources/SwiftiomaticKit/Rules/<Group>/<Name>.swift` — no class wrapper.
- Lint-only rules keep `SyntaxLintRule` (untouched — `LintPipeline` is fine).
- `RewriteSyntaxRule`, `RewritePipeline`, `RewriteCoordinator.runLegacyPipeline`, `DebugOptions.useCompactPipeline` deleted.
- All `assertFormatting`-style tests retargeted at the compact pipeline with a single-rule mask.

### Phases

**Phase 1 — Finish the transforms** (scope of `7fp-ghy`)
- Batch 3 (3 rules): `PreferSelfType`, `RedundantSelf`, `PreferEnvironmentEntry` — use `Context.ruleState` + `willEnter`/`didExit`.
- 5 reverted rules: write fresh static transforms only (no need to preserve override bodies — about to be deleted).
- After this phase, every node-local rule has a working static `transform`.

**Phase 2 — Test harness retarget**
- Add `assertFormatting(rule:input:expected:findings:)` taking a rule name (string), builds a `Context` with `Configuration.rules = [name: true]`, runs `CompactStageOneRewriter`, returns output + findings.
- Migrate ~120 rule test files: `assertFormatting(FooRule.self, ...)` → `assertFormatting(rule: "FooRule", ...)`. Mechanical.
- Verify rule mask is honored inside the generated rewriter — if not, gate each transform call on `context.isRuleEnabled(<name>)`. One-line generator change.
- Full suite green with legacy still default.

**Phase 3 — Flip default**
- `RewriteCoordinator` calls `runCompactPipeline` unconditionally.
- Full suite green. Any divergence between compact and legacy now surfaces as a test failure — fix in the static transform.

**Phase 4 — Delete legacy** (this is what `dil-cew` was for; folded in)
- Delete `RewriteSyntaxRule.swift`, `RewritePipeline.swift`, `runLegacyPipeline`, `DebugOptions.useCompactPipeline`, the rewrite section of `Pipelines+Generated.swift`, `CompactPipelineParityTests`.
- For each rule file: delete `final class FooRule: RewriteSyntaxRule<...> { override func visit ... }`. Keep static `transform` + any `Finding.Message` extensions.
- Delete `RuleCollector` paths that detect the class shell; keep only 3-arg static `transform` detection.
- Regenerate; full suite green; `sm format` diff over the project empty.

**Phase 5 — Structural passes** (out of scope)
- The 13 structural rules from `kl0-8b8` stay as ordered `SyntaxRewriter` subclasses; they're cross-tree reshapers, not node-local. Own files.

### Key decisions

- **Transform location**: free `static func transform` in an `enum FooRule` namespace per file (current pattern). Not extensions on `CompactStageOneRewriter` — generated; shouldn't own symbols.
- **Rule mask in compact rewriter**: must be wired before Phase 2 ships. Without it, single-rule tests are impossible.
- **No incremental shell deletion**: delete all `RewriteSyntaxRule` subclasses in one Phase 4 commit. Avoids half-converted state.
- **Findings parity**: static transforms already call `Self.diagnose(_:on:context:)`. After Phase 4 the per-rule `RuleBasedFindingCategory` keying must still produce identical category names — verify Phase 3.

### Risks

- **Test fixture interactions**: a few rule tests rely on a combination of rules. Single-rule mask surfaces these — fix case-by-case (enable 2-3 rules in that test).
- **Order sensitivity**: when multiple rules transform the same node type, generator must emit deterministically. Lock in alphabetical order before Phase 3.
- **`super.visit` semantics**: today's overrides call `super.visit` first (post-order). Combined rewriter does the same. Confirmed equivalent in `5r3-peg`.

### Verification gates

- Phase 1: `swift_diagnostics --build-tests` clean; parity test green.
- Phase 2: full suite green with legacy default.
- Phase 3: full suite green with compact default; `sm format` over `Sources/` produces no diff.
- Phase 4: same as Phase 3; LOC reduction visible (~120 class shells gone); perf test < 200 ms on `LayoutCoordinator.swift`.



## Revised Collapse Plan (Option 1, node-type merge — 2026-04-28)

Supersedes the immediately preceding "Collapse Plan" section. The rule-as-class concept dissolves entirely; logic organizes around the AST node type it operates on. Performance and clarity > preserving the rule abstraction.

### End state

- File layout: `Sources/SwiftiomaticKit/Rewrites/<NodeCategory>/<NodeType>.swift`. Each file owns *all* compact-style rewrites for that node type — one cohesive function instead of N chained transforms.
- "Rule" survives only as **config keys** (strings in `swiftiomatic.json` and `Configuration.rules`). Each feature block in a node-type function gates on `context.isRuleEnabled("FooName")`. Users keep the same surface; internally there are no rule classes.
- `Finding.Message` extensions move next to the feature block that emits them. `category` strings stay unchanged → diagnostic output identical.
- `CompactStageOneRewriter`'s `visit(_ T)` calls one hand-written function per node type (`rewriteDeclModifier(_:context:)`, etc.). Generator either emits a thin shim or is replaced with a hand-written rewriter — decide during Phase 4 based on what's simpler.
- Lint rules unchanged — `SyntaxLintRule` + `LintPipeline` stays.

### Phases

**Phase 1 — Finish static transforms** (scope of `7fp-ghy`, unchanged)
Still needed as the *input* to the merge. Each former rule's static transform is a clean, testable unit; merging starts from clean parts.

**Phase 2 — Test harness retarget**
`assertFormatting(rule:input:expected:findings:)` with single-key mask. The mask gates feature blocks (post-merge) the same way it gated chained transforms (pre-merge); test API survives the merge intact.

**Phase 3 — Flip default to compact.** Full suite green.

**Phase 4 — Merge by node type + delete legacy**
- Inventory: group all 122 static transforms by the `SyntaxNode` they operate on.
- For each node type, create `Sources/SwiftiomaticKit/Rewrites/<Category>/<NodeType>.swift` containing one function `rewrite<NodeType>(_ node: NodeType, context: Context) -> NodeType`.
- Hand-merge the transforms into a single coherent function: shared traversals factored, ordering made explicit and commented, each feature block gated on `context.isRuleEnabled("<key>")`. `Finding.Message` extensions relocated.
- `CompactStageOneRewriter`'s `visit(_ T)` calls into these functions.
- Delete `Sources/SwiftiomaticKit/Rules/*` rewrite files (lint files stay). Delete `RewriteSyntaxRule`, `RewritePipeline`, `runLegacyPipeline`, `DebugOptions.useCompactPipeline`, `CompactPipelineParityTests`.
- `RuleCollector` reduces to lint-rule discovery only.

**Phase 5 — Structural passes** unchanged (out of scope).

### Key decisions

- **Merge granularity**: per node type, not per former rule. If a node type has only one ex-rule, its file is a single-purpose function — fine, no churn.
- **Config keys are the new "rule registry"**: `Configuration.rules` keeps the same key set; `ConfigurationRegistry+Generated.swift` becomes hand-edited or driven by a small `[String]` constant.
- **Merge order is explicit code**: where Phase 4 finds two ex-rules that touched the same node, the merge author makes the order decision in plain Swift (with a comment if non-obvious). No "deterministic emission" hand-waving.
- **Shared work**: Phase 4 looks for shared traversals (e.g. modifier-list walks done by multiple ex-rules) and factors them. Real perf and clarity wins live here, beyond single-walk dispatch.
- **Findings ordering**: emitted in code order within each function. Diagnostic output may reorder slightly vs. legacy. Acceptable; gate Phase 3 → Phase 4 on test updates if any test asserts ordering.

### Risks

- **Phase 4 is editorial, not mechanical** — each node type needs a thoughtful merge. ~30–50 node types touched (rough estimate); a few days of careful work, reviewed file-by-file.
- **Config-key wiring**: every feature block needs a gate. Easy to miss one; add a sanity check that walks `Rewrites/` for `isRuleEnabled` calls and cross-checks against the configuration key set.
- **Lint+rewrite dual rules**: a few rules currently both lint and rewrite from the same class. After merge, the lint half stays in `Rules/` (using `SyntaxLintRule`); the rewrite half moves to `Rewrites/`. Same `RuleBasedFindingCategory` name in both files.



## Decision (2026-04-28): skip Phases 2 and 3, jump to Phase 4

Phase 2 dry-run flipped the test harness to use the compact pipeline (`pipeline.debugOptions.insert(.useCompactPipeline)` in `Tests/SwiftiomaticTests/Rules/LintOrFormatRuleTestCase.swift`). 20 tests failed because **28 rewrite rules from earlier clusters were never ported to static transforms** — they exist as `RewriteSyntaxRule` subclasses but have no `static func transform`, so the generated `CompactStageOneRewriter` doesn't dispatch them.

### The 28 unported rewrite rules

Redundancies: `RedundantOverride`, `RedundantFinal`, `RedundantEscaping`, `RedundantSwiftTestingSuite`, `NoFallThroughOnlyCases`
Types: `PreferShorthandTypeNames`, `PreferVoidReturn`, `NoVoidReturnOnFunctionSignature`, `PreferAnyObject`
Unsafety: `NoForceTry`, `NoForceCast`, `NoForceUnwrap`
Memory: `StrongOutlets`
Naming: `UppercaseAcronyms`
LineBreaks: `EnsureLineBreakAtEOF`
Conditions: `NoParensAroundConditions`, `PreferEarlyExits`
Closures: `NoTrailingClosureParens`, `NamedClosureParams`, `PreferTrailingClosures`
Wrap: `WrapMultilineStatementBraces`, `WrapMultilineFunctionChains`, `NestedCallLayout`
Indentation: `SwitchCaseIndentation`
BlankLines: `BlankLinesAroundMark`, `BlankLinesBeforeControlFlowBlocks`, `BlankLinesAfterSwitchCase`, `BlankLinesAfterGuardStatements`

(13 structural rules also lack static transforms but run as separate passes in `runTwoStageCompactPipeline` — fine.)

### Path forward

Per user direction: **skip Phase 2 (test retarget) and Phase 3 (default flip). Jump straight to Phase 4 (node-type merge + legacy delete).**

Rationale: porting these 28 to static transforms would be intermediate scaffolding that Phase 4 dissolves anyway. Writing them directly into their target node-type functions in `Sources/SwiftiomaticKit/Rewrites/<NodeCategory>/<NodeType>.swift` saves a full pass of mechanical work.

### Trade-off accepted

No incremental verification gate between Phase 1 (today) and Phase 4 (full merge). The 3-fixture parity test (`CompactPipelineParityTests`) is the only safety net during Phase 4 — and it's known insufficient (it stayed green during the Phase 1 triage that broke 50 unit tests). Phase 4 work must include test-by-test validation as each node-type function is written.

### Phase 4 entry state

- Test harness change reverted; legacy is still default.
- All 18 deferred rules ported to static transforms (Phase 1 complete via `7fp-ghy`).
- 28 rules remain class-only (no static transform). Phase 4 ports them directly into the merged node-type functions, skipping the intermediate.
- 13 structural passes stay as separate `SyntaxRewriter` subclasses.



## Resume Brief (2026-04-28, end of session)

### Status

Phase 1 (`7fp-ghy`) complete. Phase 4 foundations landed for sub-issues `49k-dtg` (4a — SourceFile), `95z-bgr` (4b — Token), `np6-piu` (4c — 14 decl types), `zvf-rsq` (4d — 13 stmt types), `mn8-do3` (4e — 19 expr/type types). 48 node types now route through hand-written `rewrite<NodeType>(_:context:)` functions in `Sources/SwiftiomaticKit/Rewrites/{Files,Tokens,Decls,Stmts,Exprs}/`. Build clean; `CompactPipelineParityTests` green throughout.

### Architecture as of now

- **Generator hook**: `Sources/GeneratorKit/CompactStageOneRewriterGenerator.swift` has `private static let manuallyHandledNodeTypes: Set<String>` (currently 48 entries). For each, the generator emits a `visit` override that:
  1. Fires `willEnter` hooks for any rule registered via `static func willEnter(_ <NodeType>, context:)`.
  2. Calls `super.visit(node)` to recurse children.
  3. Calls the hand-written `rewrite<NodeType>(_:context:)` free function on the post-traversal node.
  4. Fires `didExit` hooks.
- **Merged functions** forward to existing ported static transforms (`<RuleType>.transform(...)`) in alphabetical rule order. Unported rules have audit-only `_ = context.shouldFormat(<RuleType>.self, node: Syntax(result))` placeholders.
- **willEnter/didExit ordering bug fixed mid-session**: file-level pre-scan state must populate BEFORE descendants are visited. Prior generator emitted `let node = super.visit(node); return rewrite<NodeType>(node, context:)` which fired willEnter inside the merged function (post-traversal). Generator now emits willEnter before super.visit. `rewriteSourceFile` was edited to remove its (then-duplicate) willEnter section.
- **Filename collision risk**: Swift package can't have two `<Name>.swift` with the same basename (.o file conflict). `Layout/Tokens/Token.swift` already existed, so the Token merged file is `Rewrites/Tokens/TokenRewrites.swift`. All other merged files use the bare node-type name (`SourceFile.swift`, `ImportDecl.swift`, etc.) — verify no future collisions.

### Sub-issue status

| ID | Phase | Status | What's left |
|---|---|---|---|
| `7fp-ghy` | Phase 1 | completed | — |
| `49k-dtg` | 4a | in-progress | Inline NoForceTry/NoForceUnwrap SourceFile pre-scan into merged function (currently no-op). Otherwise foundation done. |
| `95z-bgr` | 4b | in-progress | NestedCallLayout/WrapMultilineFunctionChains/WrapMultilineStatementBraces left as audit-only at Token level — but their actual work is on structural nodes (handled in 4c/4d/4e foundations). Inline BlankLinesAroundMark and UppercaseAcronyms are done as fileprivate helpers. |
| `np6-piu` | 4c | in-progress | All 14 decl types have merged functions. Audit-only entries for unported rules: `RedundantOverride`, `RedundantFinal`, `RedundantEscaping`, `PreferAnyObject`, `StrongOutlets`, `WrapMultilineStatementBraces` (10 decl types), `RedundantSwiftTestingSuite` (instance-state pre-scan), `NoForceTry`/`NoForceUnwrap` (instance-state). |
| `zvf-rsq` | 4d | in-progress | All 13 stmt types have merged functions. Audit-only: `WrapMultilineStatementBraces` (most), `NoParensAroundConditions` (If/Guard/While/Repeat/Return/SwitchExpr/ConditionElement), `PreferEarlyExits` (CodeBlockItemList), `BlankLinesBefore/AfterControlFlow*`, `BlankLinesAfterSwitchCase`, `SwitchCaseIndentation`, `NoFallThroughOnlyCases`. |
| `mn8-do3` | 4e | in-progress | All 19 expr/type types have merged functions. Audit-only: `NoForceUnwrap` (11 types), `NoForceTry`, `NoForceCast`, `NamedClosureParams`, `NoTrailingClosureParens`, `PreferTrailingClosures`, `NestedCallLayout`, `WrapMultilineFunctionChains`, `PreferShorthandTypeNames`, `PreferVoidReturn`, `NoVoidReturnOnFunctionSignature`. |
| `2sn-0al` | 4f | ready (blocked by 4a-4e) | Test harness retarget — see below. |
| `dal-dmw` | 4g | ready (blocked by 4f) | Delete legacy — see below. |

### Remaining work, ordered

#### Step 1: Inline unported rule logic into merged functions

The audit-only `shouldFormat` calls in the merged functions are placeholders. The actual rewrite logic for these 28 rules still lives only in their `RewriteSyntaxRule` subclass `override func visit(_:)` bodies. The compact pipeline doesn't run them.

**Highest priority** (most pervasive):
- `WrapMultilineStatementBraces` — touches 10 decl types + most stmt types. Requires handling `else if` chains, brace placement, multi-line condition detection. Look at the existing `override func visit(_:)` bodies in `Sources/SwiftiomaticKit/Rules/Wrap/WrapMultilineStatementBraces.swift` for the logic.
- `NoForceUnwrap` — touches 11 node types (ForceUnwrapExpr, plus pre-scan via SourceFile/ImportDecl/Class/Function/Closure/StringLiteral/AsExpr/MemberAccess/FunctionCall/SubscriptCall). The instance `testContext: TestContextTracker` needs migration to `Context.ruleState`. Replace `testContext.visitImport(node)` etc. with state-cached equivalents.
- `NoForceTry` — same pattern as NoForceUnwrap (TestContextTracker instance state).
- `NoForceCast` — single node type (`AsExpr`), simpler.

**Lower priority** (single-node-type rules):
- `RedundantOverride`, `RedundantFinal`, `RedundantEscaping` — FunctionDecl/ClassDecl/etc.
- `PreferAnyObject` (ProtocolDecl), `PreferShorthandTypeNames` (IdentifierType + others), `PreferVoidReturn`, `NoVoidReturnOnFunctionSignature`.
- `RedundantSwiftTestingSuite` — uses instance `importsTesting` flag set during `visit(_ ImportDeclSyntax)`. Migrate to `Context.ruleState`.
- `StrongOutlets` (VariableDecl), `UppercaseAcronyms` (Token — already inlined as `applyUppercaseAcronyms` in 4b), `EnsureLineBreakAtEOF` (SourceFile — already inlined).
- `BlankLinesAroundMark` (Token — already inlined). `BlankLinesBeforeControlFlowBlocks`, `BlankLinesAfterSwitchCase`, `BlankLinesAfterGuardStatements` — multi-stmt-type logic.
- `NoParensAroundConditions`, `PreferEarlyExits`, `NoFallThroughOnlyCases`, `SwitchCaseIndentation`.
- `NamedClosureParams`, `NoTrailingClosureParens`, `PreferTrailingClosures`, `NestedCallLayout`, `WrapMultilineFunctionChains`.

**Pattern for each rule**:
1. Read the rule's `override func visit(_:)` body.
2. Translate to a `fileprivate static func applyXxx(_ node:, context:) -> NodeType` inside the corresponding merged file (or as a free function in same file).
3. Replace the audit-only `shouldFormat` call with a real gated invocation:
```swift
if context.shouldFormat(<Rule>.self, node: Syntax(result)) {
    result = applyXxx(result, context: context)
}
```
4. For instance state (e.g. `TestContextTracker`, `importsTesting`), use `Context.ruleState(for: <Rule>.self) { ... }` — see `Sources/SwiftiomaticKit/Rules/Testing/PreferSwiftTesting.swift` for the established pattern.
5. Findings: emit via `<Rule>.diagnose(.message, on: node, context: context)` if the rule has a static helper, or duplicate the message into the merged file as `fileprivate extension Finding.Message`.

#### Step 2: 4f — test harness retarget (`2sn-0al`)

Once unported rules are inlined and the compact pipeline matches legacy behavior:

1. Edit `Tests/SwiftiomaticTests/Rules/LintOrFormatRuleTestCase.swift`:
   - In the `assertFormatting` pipeline path (around line 136), add `pipeline.debugOptions.insert(.useCompactPipeline)`.
   - This was attempted earlier and surfaced 20 failures because 28 unported rules weren't in compact pipeline. After Step 1, those should pass.

2. Run full suite: `xc-swift swift_package_test`. Expect 3022+ passes.

3. Per-rule isolation issue: a few existing tests rely on multi-rule combinations. They may need `additionalRules: [String]` parameter on the helper. Address case-by-case as failures surface.

4. Run perf test: `Tests/SwiftiomaticPerformanceTests/RewriteCoordinatorPerformanceTests.swift::testTwoStageCompactPipelineOnLayoutCoordinator`. Target < 200 ms (legacy was 4.7s).

#### Step 3: 4g — delete legacy (`dal-dmw`)

1. `RewriteCoordinator.runCompactPipeline`: drop the `useCompactPipeline` debug-option branch; call `runTwoStageCompactPipeline` unconditionally.
2. Delete `DebugOptions.useCompactPipeline`.
3. Delete `Sources/SwiftiomaticKit/Syntax/Rewriter/RewritePipeline.swift`.
4. Delete `RewriteSyntaxRule` from `Sources/SwiftiomaticKit/Syntax/SyntaxRule.swift` (keep `SyntaxLintRule`).
5. Delete `Tests/SwiftiomaticTests/Sanity/CompactPipelineParityTests.swift`.
6. Remove the rewrite section of `Sources/SwiftiomaticKit/Generated/Pipelines+Generated.swift`.
7. Update `Sources/GeneratorKit/RuleCollector.swift` — drop legacy rewrite-rule detection; keep lint-rule discovery and `transform`/`willEnter`/`didExit` collection.
8. Delete the 122 rewrite rule class shells. For dual lint+rewrite rules, keep the lint half.
9. Remove the `static func transform` from rules whose logic is now inlined in merged functions (else they're duplicated).
10. Verify: full suite green, perf < 200 ms, `sm format Sources/` empty diff.

### Reference materials

- **Pattern reference for new merged functions**: `Sources/SwiftiomaticKit/Rewrites/Decls/ImportDecl.swift` (smallest), `Sources/SwiftiomaticKit/Rewrites/Files/SourceFile.swift` (largest). Both use `context.shouldFormat(<Rule>.self, node:)` and `<Rule>.transform(result, parent: parent, context: context).as(<NodeType>Syntax.self)` patterns.
- **Pattern reference for `Context.ruleState`**: `Sources/SwiftiomaticKit/Rules/Testing/PreferSwiftTesting.swift` (file-level state + scope stacks), `Sources/SwiftiomaticKit/Rules/Idioms/LeadingDotOperators.swift` (token-level transient state).
- **Generator details**: `Sources/GeneratorKit/CompactStageOneRewriterGenerator.swift` lines 102-154 contain the manually-handled-type emission. The non-handled path (line 156+) emits the per-rule chain.
- **`Context.shouldFormat` API**: defined on Context — checks rule mask + ignore directives. Pass the rule type as `<Rule>.self`. Equivalent to "is this rule enabled at this node?".
- **Generated dispatch reference**: `.build/plugins/outputs/swiftiomatic/SwiftiomaticKit/destination/GenerateCode/CompactStageOneRewriter+Generated.swift` — inspect to see exactly which rules dispatch on each node type and in what order.

### Verification commands

After every chunk of inlining work:
```sh
xc-swift swift_diagnostics --no-include-lint
xc-swift swift_package_test --filter CompactPipelineParityTests
```

Once all unported rules are inlined, also:
```sh
xc-swift swift_package_test
```
(Full suite — check for regressions in legacy-pipeline tests; compact-pipeline tests should also pass once `useCompactPipeline` is set in test harness.)

### Open questions for next session

1. `WrapSingleLineBodies` divergence flagged in Phase 1 (lacks instance `currentIndent`/`chainBaseIndent`). Phase 1 added a static transform, but it's missing nested-conditional indent state. When this rule's logic is merged into the relevant `Rewrites/Stmts/` files, that state needs to be threaded through function args or kept in a local `var` declared at the top of `rewriteIfExpr`/`rewriteGuardStmt`/etc.
2. `WrapMultilineStatementBraces` is the heaviest remaining unported rule (10+ node types). May warrant its own sub-issue (`Phase 4c.1` style) so the inlining can be reviewed in isolation.
3. The 122 rule files still have their `RewriteSyntaxRule` subclass shells. Some have `static func transform` (Phase 1 ports) AND legacy `override func visit(_:)`. After Step 3 (4g), both go. Until then, both run in their respective paths — fine.



## Progress (2026-04-28, session continuation)

- Inlined `NoForceCast` (lint-only diagnostic on `as!`) into `Sources/SwiftiomaticKit/Rewrites/Exprs/AsExpr.swift`. Pattern: gate via `context.shouldFormat(NoForceCast.self, node:)`, emit through `NoForceCast.diagnose(_:on:context:)`, message extension `fileprivate` in the merged file. Build clean (`xc-swift swift_diagnostics`).
- Per-node removal rules (`RedundantOverride`, `RedundantFinal`) don't fit the merged-function shape — `rewriteFunctionDecl` returns `FunctionDeclSyntax` so it can't yield an empty `DeclSyntax` to splice out the decl. Removal needs to migrate to the parent-list level (`MemberBlockItemList`, `CodeBlockItemList`) — flag for next session.
- `NoForceUnwrap`/`NoForceTry` require migrating instance `TestContextTracker`/`insideTestFunction`/`addedTryExpression` flags to `Context.ruleState` across SourceFile/ImportDecl/Class/Function/Closure/StringLiteral/AsExpr/MemberAccess/FunctionCall/SubscriptCall/ForceUnwrap. Significant — own sub-issue or batch.



### Additional inlines (same session)

- `PreferAnyObject` → `Rewrites/Decls/ProtocolDecl.swift` (`applyPreferAnyObject`).
- `StrongOutlets` → `Rewrites/Decls/VariableDecl.swift` (`applyStrongOutlets`).
- `NoVoidReturnOnFunctionSignature` → `Rewrites/Exprs/FunctionSignature.swift` (`applyNoVoidReturnOnFunctionSignature`).

All three follow the established pattern: `if context.shouldFormat(<Rule>.self, node:) { result = apply<Rule>(result, context:) }`, with the helper as a fileprivate function in the same file and the `Finding.Message` extension scoped fileprivate to avoid clashes with the legacy rule file's identical extension. Build clean after each.



### More inlines (same session)

- `NoTrailingClosureParens` → `Rewrites/Exprs/FunctionCallExpr.swift`. Dropped the rule's manual `rewrite(...)` re-recursion calls — children are already visited by the generator's `super.visit` before the merged function runs.
- `BlankLinesAfterGuardStatements` → `Rewrites/Stmts/CodeBlock.swift`.
- `BlankLinesAfterSwitchCase` → `Rewrites/Stmts/SwitchExpr.swift`.

Session total: 7 single-node rules now run through the compact pipeline (`NoForceCast`, `PreferAnyObject`, `StrongOutlets`, `NoVoidReturnOnFunctionSignature`, `NoTrailingClosureParens`, `BlankLinesAfterGuardStatements`, `BlankLinesAfterSwitchCase`). Build clean, warning count steady (~27).



### Even more inlines (same session)

- `NoFallThroughOnlyCases` → `Rewrites/Stmts/SwitchCaseList.swift`. Dropped re-recursion via legacy `visit(...)` calls.
- `RedundantFinal` → `Rewrites/Decls/ClassDecl.swift` (`applyRedundantFinal` + `removeFinalFromMember`). Earlier note that this rule needed parent-list deletion was wrong — it operates on a `ClassDecl` and rewrites its inner `MemberBlockItemList`, returning a `ClassDecl`, which fits the merged-function shape cleanly.

Session total: 9 single-/inner-node rules now route through compact pipeline (added `NoFallThroughOnlyCases`, `RedundantFinal`).

### Confirmed not-yet-tractable

- `RedundantOverride` — the rule replaces the entire `FunctionDecl` with an empty `DeclSyntax` to delete it. `rewriteFunctionDecl` returns `FunctionDeclSyntax`, so deletion has to happen at the parent `MemberBlockItemList` / `CodeBlockItemList` level. Defer until a parent-list pass or a different merged shape is in place.
- `RedundantEscaping` — hybrid `SyntaxVisitor` with state across multiple node types and `visitPost` hooks. Needs scope hooks ported to `Context.ruleState` (similar to RedundantSelf pattern).
- `PreferShorthandTypeNames` — ~640 lines, multi-node. Better to add a static `transform` to the existing class than to inline.
- `NoParensAroundConditions` — touches 8 stmt/expr node types. Needs a shared helpers file in `Rewrites/Shared/` to avoid duplication.
- `BlankLinesBeforeControlFlowBlocks` — touches both `CodeBlock` and `SwitchCase`; needs shared helpers.
