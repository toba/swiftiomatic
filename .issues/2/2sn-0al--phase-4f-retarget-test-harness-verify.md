---
# 2sn-0al
title: 'Phase 4f: retarget test harness + verify'
status: in-progress
type: task
priority: high
created_at: 2026-04-28T15:50:30Z
updated_at: 2026-04-28T22:42:07Z
parent: ddi-wtv
blocked_by:
    - 49k-dtg
    - 95z-bgr
    - np6-piu
    - zvf-rsq
    - mn8-do3
sync:
    github:
        issue_number: "498"
        synced_at: "2026-04-28T16:43:51Z"
---

Phase 4f of `ddi-wtv` collapse plan: retarget the test harness at the compact pipeline and verify the full suite is green.

## Tasks

- Add `assertFormatting(rule:input:expected:findings:configuration:)` overload in `Tests/SwiftiomaticTests/Rules/LintOrFormatRuleTestCase.swift` that takes a rule name (string), constructs a `Configuration` with that single key enabled, runs `RewriteCoordinator` with `.useCompactPipeline` debug option set (or unconditionally if 4g already flipped default), and verifies output + findings.
- Migrate the ~120 rule test files from `assertFormatting(FooRule.self, ...)` to `assertFormatting(rule: "FooRule", ...)`. Mechanical sed-able rewrite. Some test files have helpers already; coordinate.
- Drop the legacy direct-instance branch (`formatType.init(context:)` + `formatter.visit(...)`) from `assertFormatting` — class shells are gone after 4a-4e.
- Run full test suite (`xc-swift swift_package_test`). Expect 3022+ passes.
- Run `Tests/SwiftiomaticPerformanceTests/RewriteCoordinatorPerformanceTests.swift` — confirm `testTwoStageCompactPipelineOnLayoutCoordinator` < 200 ms.
- Address any rule-specific test failures by either fixing the merged function or updating the test (case-by-case).

## Verification gates

- `xc-swift swift_diagnostics --build-tests` clean.
- `xc-swift swift_package_test` all green.
- `sm format Sources/` produces no diff (run from a clean build).
- Perf test < 200 ms on `LayoutCoordinator.swift`.

## Notes

- A handful of tests rely on multi-rule combinations (not single-rule isolation). For those, the new helper accepts an optional `additionalRules: [String]` to enable a small set.



## Progress (2026-04-28) — Phase 4f investigation + partial fixes

Attempted to retarget `assertFormatting` to additionally run the compact pipeline alongside the legacy one. Result: 132 → 56 failures after first round of fixes. Key findings:

### Fixes landed (kept — they are correct for both pipelines)

1. **`willEnter(_ SourceFileSyntax)` for `NoForceTry` and `NoForceUnwrap`** — file-level pre-scan (`importsXCTest`) was running in `rewriteSourceFile` (post-children), too late. Moved into static `willEnter(_ SourceFileSyntax, context:)` so descendants see the populated state. Also added `willEnter(_ ImportDeclSyntax)` for `NoForceUnwrap` (`importsTesting`).
2. **Diagnostic location from pre-rewrite tree** — moved `NoForceUnwrap`'s `diagnose(.replaceForceUnwrap, on: node.exclamationMark)` and `diagnose(.doNotForceUnwrap, on: node)` calls into `noForceUnwrapPushChainNode` (which runs in `willEnter` with the original node intact). Previously the rewrite handlers ran AFTER `super.visit` rebuilt the subtree, so the `!` token's source location was lost. Same pattern for `AsExpr`. Added chain-top check in non-test path so we only diagnose the chain top (matching legacy's no-recursion semantics).

### Remaining issues for the compact assertion

Reverted the compact-pipeline branch in `assertFormatting` for now — 25 tests still fail with "output differs" even though parity test stays green and targeted unit tests pass against legacy. Hypothesis: in single-rule mode, the merged dispatchers run `super.visit` for every node type even when the rule is disabled, which may interact subtly with rules whose legacy `visit(_:)` short-circuits recursion. Needs per-rule investigation; likely each rule whose legacy `visit(_:)` returns early (without `super.visit`) needs willEnter-based equivalents for state propagation.

### Recommendation

Next session: tackle remaining 25 failures one by one. Common pattern is rules that conditionally skip recursion in legacy (`return ExprSyntax(node)` instead of `return super.visit(node)`). These need either:
- `willEnter`-based diagnose + state mutation (same fix as `NoForceUnwrap` got).
- Or the merged dispatcher needs a way to ask the rule "should I recurse?" before diving into `super.visit`.

The willEnter-based fix is preferred — keeps the existing dispatcher shape.



## Resume Brief — Phase 4f (Compact-pipeline single-rule isolation)

### Where we are

- All 25 originally-audit-only rules are now inlined into the compact pipeline (Phase 4a–4e complete).
- `CompactPipelineParityTests` (the 3-fixture multi-rule corpus) is **green**.
- All 119 single-rule unit tests for ported rules pass when run via the **legacy** pipeline (the still-default).
- `assertFormatting` (`Tests/SwiftiomaticTests/Rules/LintOrFormatRuleTestCase.swift`) currently runs only the legacy `RewriteCoordinator` path. The direct-instance `formatType.init(context:).visit(...)` branch is also still in place.
- An attempted addition of a parallel compact-pipeline branch produced 25 single-rule failures (down from 132 after diagnostic-location fixes). It was reverted to keep the suite green; the diagnostic-location and pre-scan-ordering fixes that came out of the investigation were kept because they improve correctness regardless of pipeline.

### What changed in `Sources/` that you should know about

These are correct for both pipelines and stay:

1. `CompactStageOneRewriterGenerator` now passes `parent: Syntax?` (captured before `super.visit`) to all 47 manually-handled `rewrite<NodeType>` functions. Every merged file's signature was updated.
2. Five chain-eligible expr `rewrite<NodeType>` functions return `ExprSyntax` (was concrete) so chain-top wrapping can change node shape: `ForceUnwrap`, `AsExpr`, `MemberAccess`, `FunctionCall`, `SubscriptCall`. `IdentifierType`/`GenericSpecializationExpr` updated likewise for `PreferShorthandTypeNames`. `FunctionDecl` returns `DeclSyntax` (for `RedundantOverride`'s empty-decl removal).
3. `NoForceTry`: added `static func willEnter(_ SourceFileSyntax, context:)` so `setImportsXCTest` runs **before** descendants, not after.
4. `NoForceUnwrap`: added `willEnter(_ SourceFileSyntax)` and `willEnter(_ ImportDeclSyntax)` for the same reason. **Moved diagnostic emission into `willEnter`** (`noForceUnwrapPushChainNode` → `noForceUnwrapDiagnoseForceUnwrap` / `noForceUnwrapDiagnoseAsExpr`) so finding source locations come from the pre-rewrite tree. Non-test path now checks `isTop` to mirror legacy's no-recurse semantics (only the chain top diagnoses).
5. New helpers files: `Sources/SwiftiomaticKit/Rewrites/Exprs/NoForceUnwrapHelpers.swift` (state class + chain push/pop + rewrite handlers + diagnose-in-willEnter).

### Why the compact assertion failed (root cause analysis)

The legacy `RewritePipeline` walks the tree once with all rules' `visit(_:)` overrides interleaved by `SyntaxRewriter`. A rule's override is free to **return without calling `super.visit(node)`** — that short-circuits children traversal for *all* rules, not just itself.

Several rules rely on this behavior:

- `NoForceTry.visit(_ FunctionDeclSyntax)`: returns the node unchanged for non-test functions (no `super.visit`). Children are never visited → no diagnostics inside non-test functions.
- `NoForceUnwrap.visit(_ ClosureExprSyntax)` / `visit(_ StringLiteralExprSyntax)` inside test functions: returns without recursion → force unwraps inside closures/string interpolations are invisible to the rule.
- `NoForceUnwrap.visit(_ FunctionDeclSyntax)`: the non-test branch resets `insideTestFunction = false` and recurses with `super.visit(node)`, so nested functions inside test functions are diagnosed but not rewritten.
- `RedundantOverride.visit(_ FunctionDeclSyntax)`: returns `removed(node)` (an empty `DeclSyntax`) without recursing into the body.
- `WrapMultilineStatementBraces`: each `visit(_:)` calls `super.visit(node)` first, so the body IS recursed — these tests should still work and likely fail for a different reason (formatting of the wrapped brace, possibly idempotency).
- `PreferShorthandTypeNames.visit(_ IdentifierType)`: calls `visit(genericArgumentClause.arguments)` to manually descend — in compact, children were already visited via the dispatcher's `super.visit`, so the manual descent on already-rewritten children may be a no-op (probably fine) or may double-visit (idempotent for this rule).

In compact, the `CompactStageOneRewriter` ALWAYS calls `super.visit(node)` before invoking the merged `rewrite<NodeType>` function. There is no way for a rule to short-circuit recursion. So:

- Force unwraps inside non-test-function closures **are** visited and diagnose.
- Force unwraps inside string interpolations **are** visited and diagnose.
- The body of `RedundantOverride`-removed functions **is** visited (transient, since the result is replaced with empty decl, but findings emitted during traversal still leak out).
- `NoForceTry`'s non-test-function recursion-skip can't happen — bodies of non-test functions are visited.

The current state-based mitigations (`closureDepth`, `stringInterpolationDepth`, `functionDepth`, `insideTestFunction`) handle most cases by **gating the diagnose/rewrite logic at the leaf**. They work in principle, but the 25 remaining failures show edge cases where the state isn't quite right or the equivalence isn't exact.

### Concrete failures to investigate (all in `Tests/SwiftiomaticTests/Rules/`)

Run this to get the full list:

```sh
# Step 1: re-add the compact branch in assertFormatting (reverted):
#   Tests/SwiftiomaticTests/Rules/LintOrFormatRuleTestCase.swift
# Append after the legacy pipeline assertion (right before the closing `}` of
# assertFormatting) — the snippet that builds compactPipeline with
# .useCompactPipeline + .disablePrettyPrint and asserts compactActual == expected.
#
# Step 2:
xc-swift swift_package_test --filter "NoForceUnwrap|NoForceTry|RedundantOverride|RedundantEscaping|WrapMultilineStatementBraces|NestedCallLayout|PreferShorthandTypeNames"
```

Failures observed (from prior session — counts may shift as fixes land):

- `NoForceTryTests.allowForceTryInTestCode` — non-test function in XCTestCase. Compact still rewrites/diagnoses something inside the body. Expected: byte-identical input. **Hypothesis:** legacy's `visit(_ FunctionDecl)` returns without recursing for non-test functions; compact recurses and the `TryExpr` handler bails out (`functionDepth > 0 && !insideTestFunction`), so no diagnose. But output differs — investigate whether some OTHER rule's transform is firing in the merged `rewriteCodeBlock` / `rewriteFunctionDecl`. Probably idempotent re-build mismatch. Actually likely: in non-test function frame, my `noForceTryRewriteTryExpr` returns the node unchanged — should be OK. The "output differs" may be a serialization quirk. **First step: run the test, capture actual vs expected diff.**
- `NoForceTryTests.xcTestForceTryReplaced`, `xcTestHelperNotChanged`, `xcTestNonTestMethodNotChanged` — XCTest-imports test files. Pre-scan ordering is fixed. Re-run with current state, see if these pass now.
- `NoForceUnwrapTests` (~17 failures) — see the prior session's failure list. The willEnter-based diagnostic fix probably resolved many. Re-run.
- `RedundantOverrideTests.*` (9 failures including `plainForward`) — `transform(_ FunctionDecl)` returns `DeclSyntax("")`. **Issue:** in compact, by the time `rewriteFunctionDecl` runs, the body's children have been visited and may have emitted findings (e.g., `RedundantOverride` was the only enabled rule, so its OWN gate is the only one that should fire — but as an instance rule inside `RedundantOverride.transform(...)` the fresh-instance approach's `visit(_ FunctionDecl)` does NOT recurse for the redundant case, so OK; for non-redundant it calls `super.visit` and recurses. Should be equivalent. Investigate diff.
- `WrapMultilineStatementBracesTests.multilineClassBraceWraps`, `multilineClassBraceAlreadyWrapped` — only 2 failures. Likely brace-trivia handling differs subtly. Look at the diff.

### Recommended attack plan

1. Re-add the compact branch in `assertFormatting`. Use `pipeline.debugOptions.insert(.useCompactPipeline)` + `.disablePrettyPrint`, assert output and findings.
2. Run the targeted filter above, capture **the first failing test's actual-vs-expected diff** (use `xc-swift swift_package_test` and read the failure message — `assertStringsEqualWithDiff` prints `+` / `-` lines).
3. For each failure cluster, look at the rule's legacy `visit(_:)` — if it `return`s without `super.visit`, that's the recursion-skip pattern. Mitigate by:
   - Adding a `willEnter` hook that pushes a "skip diagnose / skip rewrite" flag on the rule's `Context.ruleState`.
   - Adding the corresponding `didExit` to pop the flag.
   - Gating the rewrite handler on the flag.
4. After all failures are green, **drop the legacy `RewriteCoordinator` branch in `assertFormatting`** (keeping only compact). The direct-instance `formatType.init(context:).visit(...)` branch can also be removed.
5. Run perf test (`testTwoStageCompactPipelineOnLayoutCoordinator`) — should already be < 200 ms; the 4.7s number is for the legacy path only.
6. Hand off to phase 4g (`dal-dmw`).

### Helpful pointers (where things live)

- Merged rewrite functions: `Sources/SwiftiomaticKit/Rewrites/{Decls,Exprs,Stmts,Files,Tokens}/<NodeType>.swift`
- Per-rule willEnter/didExit hooks: in the rule class itself (e.g. `Sources/SwiftiomaticKit/Rules/Unsafety/NoForceUnwrap.swift`).
- Generated dispatcher (after a build, READ-ONLY): `.build/plugins/outputs/swiftiomatic/SwiftiomaticKit/destination/GenerateCode/CompactStageOneRewriter+Generated.swift`
- Generator (where willEnter/super.visit/rewrite/didExit ordering is encoded): `Sources/GeneratorKit/CompactStageOneRewriterGenerator.swift`
- Rule-collector (detects `static func transform/willEnter/didExit`): `Sources/GeneratorKit/RuleCollector.swift`
- `Context.ruleState(for:)` for reference-typed state caches: `Sources/SwiftiomaticKit/Support/Context.swift`
- The fresh-instance pattern (used for many newly-ported rules): see `PreferShorthandTypeNames.transform`, `NestedCallLayout.transform`, `WrapMultilineStatementBraces.transform`, `RedundantEscaping.transform`, `RedundantOverride.transform` — all do `RuleType(context: context).visit(node)`. This works when (a) the rule has no scope-bearing instance state and (b) the rule's `visit(_:)` is idempotent on already-rewritten children. **Most likely culprit for the remaining failures**: rules where (b) doesn't hold, or where the rule's `visit(_:)` short-circuits recursion in the legacy pipeline.

### Specific verification commands

```sh
# Build clean (12 warnings expected):
xc-swift swift_diagnostics --no-include-lint

# Parity (must stay green):
xc-swift swift_package_test --filter CompactPipelineParityTests

# Targeted regression after each fix:
xc-swift swift_package_test --filter "<RuleName>Tests"
```



## Update (2026-04-28) — Root-cause fix for visitAny gating

Found and fixed a long-standing bug in `RewriteSyntaxRule.visitAny` that surfaced once the compact pipeline started running structural passes without outer per-rule gates: every disabled `RewriteSyntaxRule` subclass was still firing on every node.

### The bug

`visitAny` called `context.shouldFormat(type(of: self), node)`. `shouldFormat` is generic `<R: SyntaxRule>`. When invoked from inside the base class `RewriteSyntaxRule<V>`, R bound to the **static** base type, not the dynamic subclass. Inside the generic, `R.key` returned `"rewriteSyntaxRule<BasicRuleValue>"` (the base's stringified type) and `R.defaultValue` returned `BasicRuleValue()` = `(rewrite: true, lint: .warn)` — i.e. `isActive = true`. So `configuration[R.self]` looked up the wrong key, found nothing, fell through to the base default, and reported the rule as enabled regardless of the actual configuration.

In the legacy `RewritePipeline` this was masked because the generated dispatcher already gated with `if context.shouldFormat(ConcreteRule.self, node) { … }` (concrete static R, correct lookup) before `rule.rewrite(node)` ran. In the compact pipeline's `runTwoStageCompactPipeline`, the structural passes are invoked unconditionally as `PreferFinalClasses(context: context).rewrite(current)` — so the only gate is `visitAny`'s shouldFormat call, which was broken.

Concrete symptom: every `RedundantOverride` test in single-rule mode produced `final class Foo: Bar { }` instead of `class Foo: Bar { }` — the disabled `PreferFinalClasses` was firing because its own visitAny said `isActive=true`.

### The fix

Added a non-generic `Context.shouldFormat(ruleType: any SyntaxRule.Type, node: Syntax) -> Bool` and a backing `Configuration.isActive(rule: any SyntaxRule.Type) -> Bool` plus `SyntaxRule.defaultIsActive` static. These dispatch through the existential metatype, which preserves the dynamic type. `RewriteSyntaxRule.visitAny` now uses the new overload. Comments cross-reference the footgun at all three sites.

Files: `Sources/SwiftiomaticKit/Configuration/Configuration.swift`, `Sources/SwiftiomaticKit/Support/Context.swift`, `Sources/SwiftiomaticKit/Syntax/SyntaxRule.swift`, `Sources/SwiftiomaticKit/Syntax/Rewriter/RewriteSyntaxRule.swift`.

### Impact

- Targeted regression filter (`NoForceUnwrap|NoForceTry|RedundantOverride|RedundantEscaping|WrapMultilineStatementBraces|NestedCallLayout|PreferShorthandTypeNames`): **74 → 36 failures**.
- Full suite with the compact branch enabled in `assertFormatting`: 2579 pass, 445 fail. The 445 number is much larger than the 25 quoted earlier because adding the compact branch in `assertFormatting` covers every rule test, not just the originally tracked clusters.
- `CompactPipelineParityTests` stays green (the multi-rule corpus already had every rule "enabled", so the bug was invisible to it).
- Targeted rule clusters that passed before still pass.

### What's left for 4f

The remaining 445 single-rule failures cluster into the patterns the previous resume brief described: rules whose legacy `visit(_:)` short-circuits child recursion (no `super.visit`) — `PreferEarlyExits`, `StaticStructShouldBeEnum`, `PreferExplicitFalse`, `RedundantSelf`, `HoistAwait`, `PreferVoidReturn`, plus the ones already on the radar (`NoForceUnwrap`, `NoForceTry`, `PreferShorthandTypeNames`, `WrapMultilineStatementBraces`, `RedundantOverride` is now green). Each needs the `willEnter`/`Context.ruleState` / scope-flag mitigation tailored to its specific behavior.

The visitAny fix was on the critical path for any of the structural-pass-driven failures. Without it, every rule running in stage 2 would emit findings even when disabled, so nothing else could be diagnosed reliably. Now the structural passes are correctly gated and remaining failures are about rule-specific recursion semantics, not configuration plumbing.
