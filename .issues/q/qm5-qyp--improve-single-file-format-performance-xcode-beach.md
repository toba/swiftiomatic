---
# qm5-qyp
title: Improve single-file format performance (Xcode beachball)
status: scrapped
type: epic
priority: high
created_at: 2026-04-26T20:11:57Z
updated_at: 2026-04-27T03:57:05Z
sync:
    github:
        issue_number: "458"
        synced_at: "2026-04-27T03:58:14Z"
---

## Problem

When formatting the active file in Xcode via Editor → "Format with swift-format", users experience ~1 second of beachball. This is too slow for an interactive in-editor format operation.

Xcode invokes the binary as:
```
swift-format format --assume-filename <path> [--lines/--offsets] < stdin
```

(via the symlink at `/Applications/Xcode.app/.../usr/bin/swift-format` → `/opt/homebrew/bin/sm`)

## Goals

- Identify the dominant cost in single-file format (cold-start vs. parse vs. pipeline vs. pretty-print).
- Reduce wall-clock time of `sm format <file>` on a representative file to a target that eliminates the beachball (aim < 200 ms for typical files; ideally < 100 ms).
- Avoid regressions in correctness — full rule + layout test suite must still pass.

## Investigation Plan

- [ ] Measure baseline: time `sm format` on representative files (small / medium / large) via stdin, matching Xcode's invocation.
- [ ] Profile with Instruments (Time Profiler) — record one-shot `sm format` runs.
- [ ] Inspect the breakdown:
  - process / dyld startup + ArgumentParser init
  - configuration discovery + JSON5 parsing
  - swift-syntax parse
  - FormatPipeline (sequential rewrites — count passes, identify hot rules)
  - Layout / pretty-printer
  - output write
- [ ] Compare against upstream apple/swift-format on the same file (reference at `~/Developer/swiftiomatic-ref/swift-format`).
- [ ] Write benchmark tests (Swift Testing or a dedicated benchmark target) that lock in the baseline + regression bounds.

## Likely Suspects

- Repeated AST traversal per format rule (FormatPipeline runs each rule over the whole tree sequentially).
- Configuration discovery walking the filesystem on every invocation.
- Cold-start: dyld + Swift runtime + swift-syntax module load.
- Pretty printer recomputation / token stream allocation.
- Generated dispatcher overhead.

## Optimization Candidates (apply after profiling)

- Cache parsed configuration per directory.
- Coalesce format-rule passes where rules don't conflict.
- Reuse `SourceLocationConverter` / shared context across rules.
- Reduce allocations in TokenStream / Layout.
- Investigate whether the binary can short-circuit work when `--lines` covers a small range.

## Out of Scope

- Daemon / persistent server mode (would require Xcode-side changes; nice to have but separate issue).
- Changes to the swift-format CLI surface (must remain identical per CLAUDE.md).



## Diagnostic Findings (initial measurement)

Measured `sm format` against the project on macOS 26 (arm64), release build at `/opt/homebrew/bin/sm`, project config `swiftiomatic.json`:

| File | Lines | Wall (s) | Per-line |
|---|---:|---:|---:|
| `--help` (startup only) | — | 0.00 | — |
| `Sources/ConfigurationKit/LintOnlyValue.swift` | 42 | 0.16 | 3.8 ms |
| `Sources/SwiftiomaticKit/Layout/LayoutCoordinator.swift` | 948 | 2.94 | 3.1 ms |

- Process startup is negligible (<10 ms) — dyld + ArgumentParser are fine.
- Cost is **CPU-bound** (`user` ≈ `real`, `sys` ≈ 0).
- Per-line cost is ~3 ms, scaling roughly linearly with file size.

### Root Cause Hypothesis

`Sources/SwiftiomaticKit/Generated/Pipelines+Generated.swift` — `RewritePipeline.rewrite()` contains **137 sequential `if context.shouldFormat(...) { node = Rule(context:).rewrite(node) }` blocks**, each invoking a full `SyntaxRewriter` traversal over the **root** of the tree. For a 948-line file at 3 s, that's ≈22 ms per rule pass × 137 passes.

From `Sources/SwiftiomaticKit/Syntax/Rewriter/RewritePipeline.swift`:

> we need to run each of the format rules individually over the entire syntax tree. We cannot interleave them at the individual nodes like we do for lint rules, because some rules may want to access the previous or next tokens. Doing so requires walking up to the parent node, but as the tree is rewritten by one formatting rule, it will not be reattached to the tree until the entire `visit` method has returned.

This is the upstream apple/swift-format design — but with 137 rules it dominates wall-clock time.

Secondary contributors:

- A fresh rule instance is allocated per pipeline invocation (`Rule(context: context)`), even when the rule is disabled — but the `shouldFormat` guard runs *first* before allocation in the generated code, so this is bounded.
- `SourceLocationConverter` is built once per `Context` (good).
- Each rule's `SyntaxRewriter` allocates per visited node when changes occur (immutable swift-syntax trees).

## Refined Plan

- [x] Baseline measurements
- [x] Identify dominant cost (137× full-tree rewrites)
- [x] Add a benchmark test capturing per-line cost — see `Tests/SwiftiomaticPerformanceTests/RewriteCoordinatorPerformanceTests.swift`
- [ ] Run Instruments Time Profiler on `sm format` against `LayoutCoordinator.swift` to confirm the rewrite walk is the hot path and identify any single rule that dominates
- [ ] Investigate whether the no-op rules (those that don't apply to the file's nodes) can short-circuit cheaper — e.g., gate each rule on a coarse "does this AST contain any node kinds I care about" precheck driven by the same per-node-kind dispatch table the lint pipeline uses
- [ ] Consider building a single combined `SyntaxRewriter` analogous to `LintPipeline` for the subset of format rules that don't need cross-rule ordering (the comment in `RewritePipeline.swift` explains the constraint — but many simple rules may not actually need it)
- [ ] Compare wall-clock against upstream `apple/swift-format` on the same files (reference at `~/Developer/swiftiomatic-ref/swift-format`)

## Out of Scope (for this issue, follow-ups)

- Persistent/daemon mode (would require Xcode-side cooperation)
- Reorganizing the rule architecture into per-node-kind buckets — large refactor; create a separate epic if profiling confirms it's the right approach



## Summary of Changes

- Added `Tests/SwiftiomaticPerformanceTests/RewriteCoordinatorPerformanceTests.swift` with two `measure` blocks: full pipeline (parse + rewrite + pretty-print) and rewrite-only. Build verified via `xc-swift swift_diagnostics` (succeeds; 6 pre-existing warnings).
- Recorded baseline timings (~3 ms/line, dominated by 137 sequential full-tree rewrites in `RewritePipeline.rewrite()`).

## Awaiting Review / Next Actions

- Run the new perf tests via xc-swift to capture a baseline number on this machine.
- Run Instruments Time Profiler against `sm format Sources/SwiftiomaticKit/Layout/LayoutCoordinator.swift` to confirm rewrite-pipeline dominance and surface any hotspot rule.
- Decide on optimization direction (likely a follow-up issue/epic): coalesce passes via a combined `SyntaxRewriter` analogous to `LintPipeline` for rules that don'\''t need cross-rule ordering, and/or gate each rule with a coarse node-kind precheck.



## Baseline (from new perf tests, ~400-line input, 10 iterations)

| Test | Avg (s) | Std dev |
|---|---:|---:|
| `testFullFormatPipelinePerformance` (parse + rewrite + pretty-print) | 2.225 | 0.8% |
| `testRewritePipelineOnlyPerformance` (rewrite only) | 2.124 | 0.8% |

**~95% of wall-clock time is in `RewritePipeline.rewrite()`.** Parse and pretty-print together account for only ~100 ms on this input. The fix needs to attack the 137-rules-× -full-tree-rewrite pattern, not parsing or layout.

Run via `xc-swift swift_package_test --filter RewriteCoordinatorPerformanceTests`.



## Optimization Direction — Trade-offs

### Option A — Combined-rewriter pipeline (analog of `LintPipeline`)

A single `SyntaxRewriter` where each `visit(_:)` calls every enabled rule's hook for that node kind, threading the (possibly-rewritten) node through.

**Pros**
- Order-of-magnitude potential. One tree walk vs 137 — the only path that plausibly hits the <200 ms target on a 1k-line file.
- Better cache locality: node data is hot while multiple rules touch it.
- Fewer `SourceLocationConverter` / `shouldFormat` invocations.
- Architecture parity with `LintPipeline`.

**Cons**
- Breaks the constraint cited in `RewritePipeline.swift`: rules that read parent/previous/next tokens see *unattached* subtrees mid-rewrite. Any such rule must be excluded from the combined walk or refactored to node-local.
- Rule ordering becomes load-bearing. Today Rule B sees Rule A's finished tree; in a combined walk B sees only A's transformation of the current node and walked children. Pair interactions need auditing (e.g. `BlankLinesBetweenScopes` × `EmptyExtensions`, `DocCommentsPrecedeModifiers` × `ModifierOrder`).
- Structural rules that splice/reorder across siblings (`SortImports`, `BlankLines*`, `EnsureLineBreakAtEOF`) are awkward in per-node interleaving.
- Generated dispatcher grows — rewrite return type makes codegen more complex than `LintPipeline`'s void calls.
- Hard to migrate incrementally; risks a long-lived dual system.
- Regression debugging is harder: 137 possible authors per node instead of a clean per-pass diff.

### Option B — Coarse node-kind gating per rule

Each rule declares its relevant `SyntaxKind` set. A single visitor collects the kinds present in the file; each rule's pass is skipped wholesale if the intersection is empty.

**Pros**
- Tiny, safe change. Rule contracts and ordering preserved.
- Incremental rollout — rules opt in by overriding a static `relevantNodeKinds`.
- Wrong/missing tags are safe (worst case: unnecessary work; never wrong output).
- Cheap precompute: one extra walk + 137 set checks, dwarfed by saved rewrites.
- Verifiable via the new perf test on a narrow file.

**Cons**
- Worst case unchanged. A typical Xcode active file hits most kinds; gating fires for few rules. Beachball persists on real files.
- Per-rule cost unchanged when a rule does run.
- Maintenance drag: per-rule kind set must stay in sync; could derive via codegen from `visit(_:)` overrides to reduce drift.
- Real-world wins likely 20–40 %, not the 10× needed.

### Recommended sequence

Layer them. Ship **B first** for low-risk gains and observability. Then design **A** as the strategic fix — but admit only node-local rules (token rewrites, simple expression rewrites) into the combined walk, leaving structural list-reshaping rules in the existing per-pass model. Hybrid bounds risk while capturing most of the headline win.



## Option C — Multi-pass pipeline (hybrid)

Group the 137 rules into ~10 "interaction classes". Each pass runs as one combined `SyntaxRewriter` walk (à la `LintPipeline`); passes run sequentially. Cross-pass keeps today's full-tree visibility; intra-pass rules must be node-local.

**Speedup math.** Today ≈ 22 ms × 137 = 3 s. With 12 passes ≈ 22 ms × 12 = 264 ms ceiling — ~11×, within striking distance of the <200 ms target.

### Suggested passes (rough — needs audit)

1. Token-only / trivia-only — single-token rewrites, semicolon / whitespace / naming. Largest pass, lowest risk.
2. Expression-local — `EmptyCollectionLiteral`, `CollapseSimpleIfElse`, `ExplicitNilCheck`, `CaseLet`, `AvoidNoneName`. Replace one node with a similar-shaped one; no parent inspection.
3. Modifier / accessor order — `ModifierOrder`, `RedundantAccessControl`, `AccessorOrder`, `ProtocolAccessorOrder`. Closed family with internal ordering.
4. Comment / doc — `ConvertRegularCommentToDocC`, `DocCommentsPrecedeModifiers`, `NoLocalDocComments`.
5. Body & wrap — `WrapSingleLineBodies`, `WrapMultilineStatementBraces`, `NestedCallLayout`. Often disjoint node kinds.
6. Blank lines — `BlankLinesBetweenScopes`, `BlankLinesAfterImports`, `BlankLinesAroundMark`, `BlankLinesBefore/AfterX`, `ConsistentSwitchCaseSpacing`, `EnsureLineBreakAtEOF`. Trivia reshapers; must run *after* structural changes settle.
7. Structural-but-local — `EmptyExtensions`, `CollapseSimpleEnums`, `SimplifyGenericConstraints`. Potentially co-walk if disjoint kinds.
8. Cross-tree structural (solo) — `SortImports`, `ExtensionAccessLevel`, anything that needs a fully-attached parent or sibling reordering across the file.
9. Self / type rewrites — `RedundantSelf`, `PreferSelfType`, `PreferShorthandTypeNames`, `CapitalizeTypeNames`. May need solo or pairwise grouping.
10. Catch-all / migration shelf — unclassified rules stay here, running one-rule-per-walk as today.

### Pros vs all-or-nothing combined pipeline

- Bounded blast radius. Misclassification only mis-orders rules within one pass; cross-pass contracts preserved exactly as today.
- Incremental migration. Ship pass 1 first; expand pass by pass. The catch-all pass preserves correctness indefinitely for unconverted rules.
- Audits become local: ~12² pass-orderings + intra-pass pairs instead of 137².
- Structural rules keep their guarantees (solo passes).
- Composes with Option B: each pass's combined walk benefits from coarse node-kind gating.
- Codegen-friendly: add `static var interactionClass` to `SyntaxFormatRule`; `Generator` emits one combined `SyntaxRewriter` per pass plus a driver — same template as `LintPipeline`.

### Cons / risks

- Latent interactions. Two rules that *appear* node-local can interact through trivia or shared types in ways unit tests miss. Mitigations: golden-corpus diff harness (multi-pass pipeline byte-identical to current on the fixture corpus); per-rule "force solo" config escape hatch.
- Pass assignment is a long-lived contract. New rules need a class — needs a CI lint that fails on unclassified rules.
- Speedup ceiling depends on balance. If sticky rules force more passes, you regress toward current state.
- Intra-pass caveats persist (same parent/neighbor unattachment problem as Option A, contained to one pass).
- Debugging gains a "which pass" axis — per-pass diff dumps mitigate.
- A few rules may need refactoring to fit a pass; alternative is leaving them in the catch-all (slower).

### Recommended sequence

1. Land **Option B (gating)** standalone — small change, immediate observability.
2. Land multi-pass infrastructure (interaction-class enum + codegen + driver) with all rules initially in the catch-all. Zero behavior change. Add golden-corpus diff harness here.
3. Migrate rules into pass 1 (token-only). Measure. Verify golden corpus byte-identical.
4. Expand pass by pass, lowest-risk first.
5. Stop when wall-clock hits target; remaining rules can stay on the catch-all shelf.



## Static-Validation Taxonomy

`NodeLocalFormatRule` is one slot on one axis. The full taxonomy has two orthogonal axes — what a rule may *read* and what it may *write* — plus a few optional declared properties for cases analysis can't reach. Co-walk eligibility is then mechanical: same (or compatible) read-locality bucket + disjoint write surfaces.

### Axis 1 — Read locality (compile-time enforced)

A ladder, most→least restrictive. Each base class physically denies access beyond its scope.

| Base class | May read | Example fits |
|---|---|---|
| `TokenLocalFormatRule` | The token + its trivia. No structural context. | trailing-semicolon strip, capitalization |
| `NodeLocalFormatRule` | The visited node + descendants + context config | `EmptyCollectionLiteral`, `CollapseSimpleIfElse`, `ExplicitNilCheck` |
| `DeclLocalFormatRule` | Visited node + enclosing declaration's modifiers/attributes | `ModifierOrder`, `AccessorOrder`, `RedundantAccessControl` |
| `BlockLocalFormatRule` | Enclosing statement/member-block list (siblings, not ancestors) | `BlankLinesBetweenScopes`, `ConsistentSwitchCaseSpacing` |
| `FileGlobalFormatRule` | Anything | `SortImports`, `ExtensionAccessLevel`. Always solo pass. |

Ladder is monotone: a rule at level *k* is also valid at level > *k*. Rules at the same level can potentially share a pass (subject to the write axis).

### Axis 2 — Write surface (compile-time enforced)

| Base class | May write | Example |
|---|---|---|
| `TriviaOnlyFormatRule<Channel>` | One named trivia channel only | per channel below |
| `TokenTextFormatRule` | Token text/kind in place | `CapitalizeTypeNames`, `RedundantSelf` removal |
| `ExpressionRewriteFormatRule` | Replace an expression (same slot) | `PreferShorthandTypeNames`, `EmptyCollectionLiteral` |
| `DeclRewriteFormatRule` | Replace a declaration's body / signature pieces | `WrapSingleLineBodies`, `WrapMultilineStatementBraces` |
| `ListReshapingFormatRule<CollectionKind>` | Insert/remove elements of a specific collection kind | `EmptyExtensions`, `SortImports` |

Trivia channels:

| Channel | Used by |
|---|---|
| `.blankLines` | `BlankLines*`, `EnsureLineBreakAtEOF` |
| `.lineComments` | `NoLocalDocComments` (strip mode) |
| `.docComments` | `ConvertRegularCommentToDocC`, `DocCommentsPrecedeModifiers` |
| `.ignoreDirectives` | reserved for `// sm:ignore` rewrites |
| `.horizontalSpaces` | pretty-printer only, not user rules |

Two `TriviaOnlyFormatRule`s can share a pass iff their channel parameters differ — the analyzer reads it off the generic parameter, no body inspection needed.

### Co-walk decision

```
SamePassOK(A, B)
  ⇐  ReadLocality(A) == ReadLocality(B)
   ∧  WriteSurfacesDisjoint(A, B)
   ∧  KindSetDisjoint(A, B) ∨ NoOrderingHazard(A, B)
```

`KindSet(R)` is free from `visit(_:)` overrides. `NoOrderingHazard` holds when both rules write *different fields* of the same node — visible from `with(\.field, …)` builder calls, no semantic reasoning required.

### Axis 3 — Optional declared properties (small, marker-style)

- **`Idempotent`**: `R(R(x)) == R(x)`. Lets the planner re-run the rule cheaply or place it freely.
- **`MonotonicWrite<Channel>`**: only adds, or only removes, in its channel — never both. Two monotonic-add rules on the same channel can co-walk; their effects compose by union.
- **`MustRunAfter<Other>` / `MustNotShareWith<Other>`**: narrow, named escape hatches for the rare case where analysis is correct but pessimistic. Every use is a code-review trigger.

### What this taxonomy buys

- 5 read-locality buckets × ~5 write-surface buckets = ~25 cells; most empty or single-occupant. Pass assignment becomes "which cells can co-walk?" — a small graph problem.
- Field-level write disjointness is visible at the call site (`with(\.leadingTrivia, …)` vs `with(\.modifiers, …)`), so codegen can detect overlap without semantic reasoning.
- Trivia-channel typing is the single highest-leverage move — eliminates the otherwise-unanalyzable order dependence among the many trivia-touching rules.
- Escape hatches are explicit, named, and rare. No "trust the author" annotations on the common path.

### Honest residual

1. Picking the right base class for a new rule — same problem as picking an `interactionClass`, but constrained by what APIs the rule actually uses. The compiler refuses incorrect choices.
2. Field-level overlap that's semantically order-dependent but syntactically disjoint (e.g., two rules producing a new `IfExprSyntax` with different bodies). Caught by golden-corpus diff harness, not the type system.
3. The catch-all pass. Some rules genuinely won't fit any cell and live in `FileGlobalFormatRule` as solo passes — fine, the architecture admits them.



---

## Decision (supersedes prior Options A / B / C trade-offs above)

Direction: **multi-pass rewrite pipeline with statically derived pass partition** (per `## Static-Validation Taxonomy` below). Not pursuing per-rule node-kind gating standalone, and not pursuing the all-or-nothing combined-pipeline variant. The earlier Options A, B, C sections are kept above for context but the recommendations in those sections are obsolete.

Replace `RewritePipeline.rewrite()` (137 sequential walks) with ~10 passes. Each pass is one combined `SyntaxRewriter` walk that interleaves all rules assigned to it. Cross-pass behavior preserves today's full-tree visibility, so structural rules keep their guarantees.

**Pass assignment is statically derived, not author-declared.** Pass membership comes from each rule's constrained base class (read-locality × write-surface, per the taxonomy) plus a tiny set of marker protocols. Codegen computes the partition. Misclassification is a compile error (constrained base classes deny APIs the rule shouldn't use), not a runtime bug.

**Speedup target.** Today ≈ 22 ms × 137 = 3 s. With ~12 passes ≈ 22 ms × 12 = 264 ms ceiling — within the <200 ms target on a 1k-line file.

**Safety net.** A golden-corpus diff harness exercises the existing pipeline against the entire test fixture corpus and snapshots the output; the multi-pass pipeline must produce byte-identical output on every CI run before any rule migration ships.

### Implementation sequence

1. Design constrained base classes per the taxonomy.
2. Land golden-corpus diff harness against existing test fixtures.
3. Land multi-pass `Generator` extension + driver, all rules initially in the catch-all (zero behavior change).
4. Migrate pass 1 (token-only); verify golden corpus byte-identical; measure perf delta.
5. Expand pass by pass, lowest-risk first. Stop when wall-clock hits target.


## Reasons for Scrapping

The multi-pass architecture's premise — that ~137 format rules cluster into ~10 wide combined-rewriter passes — is empirically refuted by the rule corpus.

Audit results:
- 48 rules read `.parent` / `.previousToken` / `.nextToken`.
- 12 carry mutable instance state across visits.
- 18 span multiple node kinds for one cross-cutting concern.
- 9 reshape parent collections.

That's 87 of 137 rules disqualified from any combined pass before semantic write-disjointness analysis even begins. The remaining ~50 rules fragment across token / node / decl / block locality buckets:
- Pass 1 (TokenLocalFormatRule): 3 rules, all on the same trivia channel — co-walk requires monotonicity proofs the rules don't have. Save: ~44 ms.
- Pass 2 (NodeLocalFormatRule): ~8 rules, two of them collide on `OptionalBindingConditionSyntax`. Save: ~154 ms.
- Combined pass-1 + pass-2 ceiling ≈ 200 ms against a 3 s baseline ≈ 7%, not the 11× the epic targeted.

The infrastructure landed (markers, driver, codegen, manifest) cannot earn its keep on this rule population. Reverted in a follow-up commit. The golden-corpus harness from `m82-uu9` is preserved — it's an independent regression net useful for any future formatter change.

Better paths for follow-up perf work:
- Per-rule node-kind gating (the rejected "Option B"): coarse precheck driven by `RuleCollector.syntaxNodeLinters`. Skips a rule's full-tree walk when the file contains zero relevant node kinds. Estimated 20–40% wall-clock reduction with no semantic risk.
- Rule-architecture refactor that pushes more rules toward node-local by removing `.parent` reads — multi-quarter effort.
- Daemon mode (was out of scope) — sidesteps per-invocation cost; needs Xcode-side cooperation.
