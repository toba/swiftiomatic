---
# ddi-wtv
title: Cut over to `compact` pipeline; delete superseded rule files
status: in-progress
type: feature
priority: high
created_at: 2026-04-28T01:41:38Z
updated_at: 2026-04-29T04:13:14Z
parent: iv7-r5g
blocked_by:
    - eti-yt2
    - o72-vx7
    - e4v-075
sync:
    github:
        issue_number: "480"
        synced_at: "2026-04-29T05:35:26Z"
---

## Goal

Replace `FormatPipeline` with the two-stage style-driven architecture from epic `iv7-r5g`, fold the per-rule `RewriteSyntaxRule` shells into hand-written `rewrite<NodeType>(_:context:)` functions, and delete the now-orphaned files.

### Pipeline shape

1. **`CompactStageOneRewriter`** — every node-local normalization in a single tree walk, generated dispatch (`Sources/GeneratorKit/CompactStageOneRewriterGenerator.swift`).
2. **Structural passes** (≤13) — `SortImports`, blank-line policy, `ExtensionAccessLevel`-style cross-tree reshapers, in the order from `2kl-d04` §2.
3. **Pretty-print** — unchanged.

### Phases

- **Phase 1** (`7fp-ghy`, completed): extract static `transform(_:parent:context:)` from per-rule `RewriteSyntaxRule` overrides.
- **Phase 4a–4e** (`49k-dtg`, `95z-bgr`, `np6-piu`, `zvf-rsq`, `mn8-do3`, all in-progress): hand-written `rewrite<NodeType>(_:context:)` free functions in `Sources/SwiftiomaticKit/Rewrites/<Group>/<NodeType>.swift`. The generator emits a thin override that calls `willEnter` hooks → `super.visit(node)` → the merged free function → `didExit` hooks.
- **Phase 4f** (`2sn-0al`): retarget the test harness to `pipeline.debugOptions.insert(.useCompactPipeline)` and verify the full suite passes.
- **Phase 4g** (`dal-dmw`): flip default in `RewriteCoordinator`, delete `RewritePipeline`, `RewriteSyntaxRule`, `useCompactPipeline` debug option, `CompactPipelineParityTests`, and the rewrite section of `Pipelines+Generated.swift`. Drop the 122 legacy rule shells (keep the lint half of dual lint+rewrite rules).
- **Phase 5** (out of scope): structural passes from `kl0-8b8` stay as ordered `SyntaxRewriter` subclasses.

## Resume Brief — Phase 4 Inlining

Per-rule details live on the child issues (`49k-dtg`, `95z-bgr`, `np6-piu`, `zvf-rsq`, `mn8-do3`). This section is the high-level state for resuming work in a fresh session.

### Status

- **25 rules** inlined into the compact pipeline. Build clean; warning count 12 (down from 30 at the start of phase 4 inlining). All originally-audit-only rules now inlined.
- `CompactPipelineParityTests` stays green throughout. Compact pipeline is **not** the default — toggled via `DebugOptions.useCompactPipeline`.
- Phase 4 sub-issues (`49k-dtg`, `95z-bgr`, `np6-piu`, `zvf-rsq`, `mn8-do3`) are all in-progress; their bodies list exactly what was inlined into each merged-file directory.

### Audit-only entries remaining

These are `_ = context.shouldFormat(<Rule>.self, node: ...)` placeholders in merged files where the rule's logic still lives only in its legacy `RewriteSyntaxRule` subclass:

| Rule | Occurrences | Disposition / next action |
|---|---|---|




Find the current count any time with:

```sh
grep -rn "_ = context.shouldFormat" Sources/SwiftiomaticKit/Rewrites/ \
  | grep -v "// " \
  | awk -F'shouldFormat\\(' '{print $2}' \
  | awk -F'\\.self' '{print $1}' \
  | sort | uniq -c | sort -rn
```

### Patterns proven this phase

1. **Stateless single-/inner-node rules:** plain `apply<Rule>(_:context:)` helper + `fileprivate Finding.Message` extension in the same merged file. Reference: `Rewrites/Decls/ProtocolDecl.swift::applyPreferAnyObject`.
2. **Stateless multi-node rules:** dedicated `<RuleName>Helpers.swift` next to the merged files; each `rewrite<NodeType>` calls into the shared helpers. Reference: `Rewrites/Stmts/NoParensAroundConditionsHelpers.swift` (8 callers across 8 merged files).
3. **File-level state:** reference-typed state class cached via `Context.ruleState(for:)`, populated by the relevant pre-scan node (e.g. `ImportDecl`). Reference: `Rewrites/Decls/RedundantSwiftTestingSuiteHelpers.swift`.
4. **Scope-bearing state:** static `willEnter(_ T, context:)` / `didExit(_ T, context:)` on the rule class — generator's `RuleCollector` (`Sources/GeneratorKit/RuleCollector.swift`) picks them up automatically and emits hook calls before/after `super.visit` in `CompactStageOneRewriter+Generated.swift`. Reference: `Rewrites/Exprs/NoForceTryHelpers.swift` + the static `willEnter`/`didExit` overloads at the bottom of `Rules/Unsafety/NoForceTry.swift`.

### Compact pipeline call order (from generator)

For each manually-handled node type, `CompactStageOneRewriter.visit(_ T)` emits:

1. `willEnter(...)` calls (one per registered rule, gated on `context.shouldFormat`).
2. `let visited = super.visit(node)` — recurses children.
3. `let result = rewrite<NodeType>(visited, context:)` — the merged free function in `Rewrites/<Group>/<NodeType>.swift`.
4. `didExit(...)` calls.
5. `return result`.

Knowing this is essential for state-bearing rules: `willEnter` runs **before** descendants are visited, so it's where pre-scan flags get set. The merged `rewrite<NodeType>` runs **after** children but **before** `didExit`, so it can read state accumulated during traversal (e.g. `state.convertedForceTry`) and apply post-traversal modifications.

### Recommended next-session order

1. **`NoForceUnwrap`** — high value (clears 11 audit-only sites). Follow the proven `NoForceTry` shape (`Rewrites/Exprs/NoForceTryHelpers.swift`) and add the chain-top wrapping logic on top: `chainNeedsWrapping` flag, `classifyChainTopContext` (`wrap`/`noWrap`/`propagate`), `wrapInUnwrap` for `XCTUnwrap`/`#require`, plus `MemberAccess`/`FunctionCall`/`SubscriptCall`/`AsExpr` handlers. Reference legacy: `Rules/Unsafety/NoForceUnwrap.swift`.
2. **`PreferShorthandTypeNames`** — port as a static `transform(_:parent:context:)` on the existing class rather than inlining 640 lines. Lowest-risk path for this rule.
3. **`WrapMultilineStatementBraces`** — biggest outstanding; create a dedicated sub-issue. Consider whether brace-placement belongs in stage 1 at all or should be a structural pass.
4. **`RedundantOverride`** — design decision needed before attempting: parent-list-level deletion vs. deletion-sentinel pattern.
5. **`RedundantEscaping`** — hybrid visitor; port using the `willEnter`/`didExit` + `Context.ruleState` pattern (closure depth + variable-decl tracking).

### Key files (entry points)

- `Sources/SwiftiomaticKit/Rewrites/<Group>/<NodeType>.swift` — merged rewrite functions (one per node type).
- `Sources/SwiftiomaticKit/Rewrites/<Group>/<RuleName>Helpers.swift` — multi-file helpers per rule.
- `Sources/SwiftiomaticKit/Support/Context.swift` — `Context.ruleState(for:initialize:)` for reference-typed state cache, `shouldFormat` for rule-mask gating.
- `Sources/SwiftiomaticKit/Syntax/SyntaxRule.swift` — static `Self.diagnose(_:on:context:)` helper used by all inlined rules.
- `Sources/GeneratorKit/CompactStageOneRewriterGenerator.swift` — emits the dispatcher; lines 100-180 contain the manually-handled-type emission with the willEnter / super.visit / rewrite<NodeType> / didExit ordering.
- `Sources/GeneratorKit/RuleCollector.swift` — detects 3-arg `transform`, `willEnter`, and `didExit` static functions on rule classes. Runs as part of the build plugin; new hooks are picked up automatically next build.
- Generated dispatcher (after a build): `.build/plugins/outputs/swiftiomatic/SwiftiomaticKit/destination/GenerateCode/CompactStageOneRewriter+Generated.swift` — inspect to verify which rules dispatch on each node type and in what order.

### Verification commands

```sh
xc-swift swift_diagnostics --no-include-lint
xc-swift swift_package_test --filter CompactPipelineParityTests
```

Full suite (slower, runs everything against the still-default legacy pipeline):

```sh
xc-swift swift_package_test
```

### Reference materials

- `Sources/SwiftiomaticKit/Rules/Testing/PreferSwiftTesting.swift` — pattern for `Context.ruleState` (file-level state + scope stacks).
- `Sources/SwiftiomaticKit/Rules/Idioms/LeadingDotOperators.swift` — pattern for token-level transient state.
- `Sources/SwiftiomaticKit/Rules/Redundancies/RedundantSelf.swift` — pattern for multi-stack scope tracking via `willEnter`/`didExit`.
- `~/.claude/plans/in-that-case-let-glittery-hopper.md` — Batch 1/2/3 strategy and the `Context.ruleState` + `willEnter`/`didExit` infrastructure design.



## Session 2026-04-28 — Phase 4f near-completion

`2sn-0al` (Phase 4f) drove single-rule failures **304 → 5** with the compact pipeline enabled in `assertFormatting`. See that issue for the full failure-cluster breakdown and per-fix log.

### Patterns established this session

1. **Widening cast-back (Pattern A)**: when a rule's `transform` returns a different concrete kind than its input, `applyRule` silently drops the result. Replace with direct dispatch + early return when the kind changes. Applied to PreferToggle, PreferIsEmpty, RedundantNilCoalescing, PreferDotZero, RedundantClosure, URLMacro, PreferCountWhere, RedundantStaticSelf, PreferSwiftTesting.
2. **RuleCollector extension scan**: `detectSyntaxRule` now folds in members from same-file extensions of the rule type. Without this, rules whose hooks live in extensions (e.g. WrapSingleLineBodies) were invisible to the dispatcher generator.
3. **Diagnostic location (Pattern B)**: move `diagnose(...)` calls into a static `willEnter` so finding source locations come from the pre-traversal (still-attached) node. The transform stays post-recursion and only rewrites. Applied to NoSemicolons, OneDeclarationPerLine, BlankLinesBeforeControlFlowBlocks, NoTrailingClosureParens, SwitchCaseIndentation, NoFallThroughOnlyCases, NoParensAroundConditions.
4. **Recursion-skip mimicry**: legacy rules that short-circuit `super.visit` in certain contexts (NoForceUnwrap in non-test code through chain-eligible parents; NoGuardInTests inside closures) need state-stack hooks (`willEnter` push, `didExit` pop) to suppress descendant work in compact mode.

### Remaining 5 failures (all on 2sn-0al's plate)

- 3 SingleLineBodies nested-body indent — need a per-rule indent stack via `Context.ruleState`.
- 2 GuardStmt pretty-printer-idempotency — likely pre-existing, separate concern.

Phase 4g (`dal-dmw`) remains blocked on 4f's full closure.



## Session 2026-04-29 (continued) — strip passes 6 + 7

Two more dead-shell strip passes landed (commits 356e4b3f, 0e23222a):

- **Pass 6** (9 rule files, 500 deletions): PreferEarlyExits, NoTrailingClosureParens, OneDeclarationPerLine, BlankLinesBeforeControlFlowBlocks, PreferVoidReturn, NamedClosureParams, PreferSelfType (6 decl-shells + member-access), RedundantPattern, NoBacktickedSelf.
- **Pass 7** (5 rule files, 741 deletions): RedundantReturn (4 visits + ~12 helpers), NoFallThroughOnlyCases (1 + 5), NoForceTry (6 + 3 instance vars), NoGuardInTests (6 delegators), PreferSwiftTesting (6 + 3 conversion helpers).

Build clean at 13 warnings (unchanged). Full suite: 3012 pass / 2 pre-existing GuardStmt pretty-printer-idempotency failures.

`override func visit` total in `Sources/SwiftiomaticKit/Rules/`: **292** (down from 333 at session start).

### Remaining 4g work

- Per-rule analysis (state-machines / conditional logic): RedundantSelf (22), WrapMultilineStatementBraces (16), NoForceUnwrap (11), WrapSingleLineBodies (10), RedundantEscaping (9), NoParensAroundConditions (8).
- Fresh-instance pattern: PreferShorthandTypeNames, NestedCallLayout (the override IS the rewrite).
- WrapTernary (kept until layout test harness retargeted).
- After all overrides are gone: delete `RewriteSyntaxRule` base class itself + drop legacy detection paths in `RuleCollector`.
