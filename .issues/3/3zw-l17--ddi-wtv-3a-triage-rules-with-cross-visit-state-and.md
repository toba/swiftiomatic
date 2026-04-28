---
# 3zw-l17
title: 'ddi-wtv-3a: triage rules with cross-visit state and recursive rewriter calls'
status: ready
type: task
priority: high
created_at: 2026-04-28T03:05:15Z
updated_at: 2026-04-28T03:05:15Z
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
