---
# ddi-wtv
title: Cut over to `compact` pipeline; delete superseded rule files
status: in-progress
type: feature
priority: high
created_at: 2026-04-28T01:41:38Z
updated_at: 2026-04-28T15:42:14Z
parent: iv7-r5g
blocked_by:
    - eti-yt2
    - o72-vx7
    - e4v-075
sync:
    github:
        issue_number: "480"
        synced_at: "2026-04-28T16:43:49Z"
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
