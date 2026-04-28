---
# ddi-wtv
title: Cut over to `compact` pipeline; delete superseded rule files
status: in-progress
type: feature
priority: high
created_at: 2026-04-28T01:41:38Z
updated_at: 2026-04-28T20:03:25Z
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
