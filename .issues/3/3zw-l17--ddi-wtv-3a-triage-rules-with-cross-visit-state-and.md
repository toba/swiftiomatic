---
# 3zw-l17
title: 'ddi-wtv-3a: triage rules with cross-visit state and recursive rewriter calls'
status: completed
type: task
priority: high
created_at: 2026-04-28T03:05:15Z
updated_at: 2026-04-28T03:36:01Z
parent: ddi-wtv
---

The static `transform` model in ddi-wtv-3 / 4 / 5 assumes a rule's logic is a pure function of a single node. Two patterns break that assumption.

## Patterns

1. **Cross-visit instance state** — e.g. `NamedClosureParams.insideMultilineClosure` set on a `ClosureExprSyntax` visit and read on a `DeclReferenceExprSyntax` visit. State lives on the rewriter, not in any single node.
2. **Recursive rewriter calls** — e.g. `NoTrailingClosureParens.visit(_:)` calls `self.rewrite(Syntax(...))` to manually recurse into a sub-expression mid-visit.

Search for offenders:

```sh
# State pattern: stored vars on RewriteSyntaxRule subclasses
grep -rn "private var \|fileprivate var " Sources/SwiftiomaticKit/Rules
# Recursive rewriter calls inside a visit body
grep -rn "rewrite(Syntax" Sources/SwiftiomaticKit/Rules
```

## Decisions to make

- **(a) Host state on the rewriter.** Add per-rule mutable state slots on `CompactStageOneRewriter`; pass them to `transform` via `inout` parameter. Keeps everything in one walk; uglier API.
- **(b) Leave on legacy.** Don't port these rules; they continue to run as separate `SyntaxRewriter` passes after the combined rewriter. Acceptable if the count is small (<5).
- **(c) Restructure.** Rewrite the rule's logic so single-node-local. May not always be possible.

## Tasks

- [ ] Enumerate all offenders (commit a list under each pattern)
- [ ] Pick disposition per rule (a/b/c)
- [ ] Document the chosen mechanism in the architecture notes (or a follow-up if (a) is chosen — needs a generator extension)

## Done when

Every offender has a disposition recorded; ddi-wtv-3 / 4 / 5 can resume without ambiguity.



## Update from cluster audits

The cluster audits in `vz0-31g` and `5r3-peg` revealed a **third pattern** beyond the original two: **parent-walking**.

### Pattern 3: Parent-walking

Rules read `node.parent` (often via `while let parent = current.parent`) to determine eligibility. `SyntaxRewriter.super.visit(node)` returns a *detached* node — calling parent on the result yields nil. The combined rewriter's default emission (`super.visit` first, then transform) silently breaks these rules.

Counts (from cluster audit):

- **Access/**: `ACLConsistency` (already ported with pre-recursion in `vz0-31g`)
- **Closures/**: `PreferTrailingClosures.isInConditionalContext`
- **Conditions/**: indirect via `elseAvailabilityCheckChainInvolved`, etc.
- **Declarations/**: `ProtocolAccessorOrder`
- **Hoist/**: `HoistAwait`, `HoistTry`
- **Idioms/**: `NoAssignmentInExpressions`, `NoVoidTernary`, `PreferCountWhere`, `PreferExplicitFalse`

Total: 8+ rules in just the first two clusters.

### Decision options for parent-walking

- **(d) Pre-recursion ordering** for ALL rules: emit `var transformed = node; transformed = Rule.transform(transformed); ...; return super.visit(transformed)`. Preserves parent access on the first transform invocation. Successive transforms see modified-but-detached nodes.
- **(e) Pass parent explicitly**: extend `transform` signature to `transform(_ node: T, parent: Syntax?, context: Context)`. Combined rewriter captures `node.parent` before super.visit and forwards it. Cleanest semantics but changes every rule's signature.
- **(f) Per-rule opt-in**: rules that need parent declare it via a marker (e.g. `static let needsParent = true`); generator emits two visit-body shapes accordingly.

Recommend **(e) — explicit parent**. It's a one-shot signature change before mass refactor; rules that don't need parent simply ignore the argument.

## Tasks (revised)

- [ ] Decide on disposition between (d), (e), (f) — recommend (e)
- [ ] If (e): update `SyntaxRule.diagnose` and the static-transform conventions; update `CompactStageOneRewriterGenerator` to emit the parent capture
- [ ] Re-port the deferred rules from `vz0-31g` and `5r3-peg` once the signature is settled
- [ ] Then handle the cross-visit-state pattern (smaller, ~6 rules)



## Summary of Changes

Resolved Pattern 1 (parent-walking) by extending the static-transform contract to a 3-arg signature: `static func transform(_ node: T, parent: Syntax?, context: Context) -> R`. The combined-rewriter generator captures `Syntax(node).parent` *before* `super.visit` detaches the node, then forwards it to each rule's transform.

Patterns 2 (cross-visit state) and 3 (recursive rewrite) are deferred to legacy ordered passes — they join the 13 structural passes from `2kl-d04` in `g6t-gcm`. Total: ~25 sequential passes, still ~5× fewer than today's 137.

### Files modified

- `Sources/GeneratorKit/RuleCollector.swift` — only detect 3-arg `transform` signatures; 2-arg shapes treated as not-yet-ported.
- `Sources/GeneratorKit/CompactStageOneRewriterGenerator.swift` — emit `let parent = Syntax(node).parent` before `super.visit` and forward to each rule's transform.
- 12 already-ported rules updated to the 3-arg signature.
- `Sources/SwiftiomaticKit/Rules/Idioms/NoVoidTernary.swift` — first parent-walking rule ported using the new shape (validation case). Test suite green.

### Effect

`5r3-peg` and `r0w-l4r` are unblocked. The ~20 parent-walking rules across all clusters can now be ported with no architectural surprises.
