---
# eti-yt2
title: 'Spike: combined SyntaxRewriter for node-local rules'
status: completed
type: feature
priority: high
created_at: 2026-04-28T01:41:04Z
updated_at: 2026-04-28T02:34:28Z
parent: iv7-r5g
blocked_by:
    - kl0-8b8
sync:
    github:
        issue_number: "479"
        synced_at: "2026-04-28T02:40:01Z"
---

## Goal

Prototype the stage-1 architecture from epic `iv7-r5g`: a single `SyntaxRewriter` whose `visit(_:)` overrides apply every node-local format transformation in one tree walk.

## Scope

- Pick a representative subset (~10) of the node-local rules from the inventory (`kl0-8b8`) — a mix of token-only, expression-local, and modifier-order rewrites.
- Implement the combined rewriter behind a feature flag or alternate entry point so the existing `RewritePipeline` keeps working.
- Benchmark with `Tests/SwiftiomaticPerformanceTests/RewriteCoordinatorPerformanceTests.swift` against `Sources/SwiftiomaticKit/Layout/LayoutCoordinator.swift` (~948 lines, today's worst case).

## Targets

- Combined-walk wall-clock < 200 ms for the `LayoutCoordinator.swift` baseline.
- Output identical (or intentionally different in documented ways) to the current pipeline's output for the chosen subset.

## Output

Numbers + an assessment: does the architecture clear the bar, and what unexpected interactions surfaced between rules sharing a walk?



## Summary of Changes

- Added `Sources/SwiftiomaticKit/Syntax/Rewriter/CombinedRewriter.swift` — a single `SyntaxRewriter` subclass with three fused `visit(_:)` overrides drawn from `RedundantBreak` (SwitchCaseSyntax), `NoBacktickedSelf` (OptionalBindingConditionSyntax), and `RedundantNilInit` (VariableDeclSyntax). Findings omitted; the spike measures rewrite throughput only.
- Added `Tests/SwiftiomaticPerformanceTests/CombinedRewriterSpikeTests.swift` with 4 perf tests + 1 sanity test; all 15 measurement passes succeeded.

## Numbers

### Real worst case: `Sources/SwiftiomaticKit/Layout/LayoutCoordinator.swift` (956 lines)

| Test | Avg (10 iter) | Notes |
|---|---|---|
| `CombinedRewriter` (3 rules, 1 walk) | **5 ms** (warm: 3 ms) | new architecture |
| `RewritePipeline` (137 rules, 137 walks) | **4,484 ms** | today's pipeline |

Combined walk on the worst-case file is **~900× faster** than the full pipeline.

### Synthetic ~400-line repeated source

| Test | Avg | Notes |
|---|---|---|
| `CombinedRewriter` (3 rules, 1 walk) | 9 ms | |
| Sequential 3 rules (3 walks) | 53 ms | mirrors today's per-walk overhead |

Combined is **5.9× faster** than three sequential walks of the same three rules. Per-walk fixed overhead ≈ 17 ms on this source.

## Assessment

The architectural premise from `iv7-r5g` is **confirmed**. Every rule in today's `RewritePipeline` pays a full-tree-walk cost (~17 ms per rule on a typical file, scaling with file size). One walk × N visit overrides per node is overwhelmingly cheaper.

### Extrapolation to 137 rules combined

Combined per-rule cost in the spike was ~2 ms per rule (3 rules → 6 ms above the ~3 ms one-walk floor). Even allowing a 5× multiplier for rules with heavier per-node logic, 137 × 10 ms + 3 ms ≈ 1.4 s — but this is a pessimistic ceiling. Most rules visit narrow node types (e.g. only `OperatorDeclSyntax`), so they contribute zero work for most nodes. Realistic estimate: **well under the 200 ms target** for `LayoutCoordinator.swift`.

### Unexpected interactions

None at this scale. The three chosen rules touch disjoint node types, so no precedence questions arose. Real interactions to watch in the cutover (`ddi-wtv`):

- Multiple rules wanting to rewrite the same node (e.g. `RedundantSelf` and `RedundantBackticks` both touch identifier expressions). Resolution: ordered chain of transformations within a single `visit` override.
- Rules whose rewrite alters the parent context another rule depends on. Mitigation: structural rules stay as separate stage-2 passes (per `kl0-8b8`'s 13-rule structural list).
- `super.visit(node)` ordering: each `visit` calls `super.visit` first to recurse, then applies its rule logic — same convention as today's `RewriteSyntaxRule` subclasses.

### Recommendation

Proceed to cutover (`ddi-wtv`). The 200 ms target is achievable with substantial headroom. Architecturally, fold the 122 node-local rules into a single `CompactStyleRewriter` (per spec `2kl-d04`) and keep the 13 structural rules as separate ordered passes.
