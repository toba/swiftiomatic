---
# 7x2-5eg
title: Migrate token-only rules to first multi-pass walk
status: ready
type: task
priority: high
created_at: 2026-04-26T21:23:50Z
updated_at: 2026-04-26T21:59:10Z
parent: qm5-qyp
blocked_by:
    - ain-794
sync:
    github:
        issue_number: "464"
        synced_at: "2026-04-26T22:01:43Z"
---

Parent: `qm5-qyp` (Improve single-file format performance).

## Goal

Migrate the **first pass** — token-only / trivia-only rules — from the catch-all into a real combined `SyntaxRewriter` walk. This is the lowest-risk migration and the proof point for the multi-pass architecture.

## Candidate rules for this pass

(Verify against the actual rule list; this is the starting set.)

- Single-token rewrites: trailing semicolon strip, `RedundantSelf` (when removing only the `self` token), `CapitalizeTypeNames`.
- Whitespace-only fixes that don't reshape lists.
- Naming-only fixes that mutate token text in place.

Any rule whose `visit(_:)` body either:

- Reads only the visited node + its trivia, and
- Writes only the token's text/kind or one trivia channel,

is a candidate. Use the constrained base classes from the taxonomy issue (`TokenLocalFormatRule` + `TokenTextFormatRule` or `TriviaOnlyFormatRule<Channel>`) to migrate them.

## Deliverables

- [ ] Each candidate rule migrated to inherit/conform to the constrained base classes.
- [ ] Generator places them in pass 1 automatically (verify via `PassManifest.md`).
- [ ] Golden-corpus harness still byte-identical.
- [ ] Performance test (`RewriteCoordinatorPerformanceTests`) shows measurable improvement.

## Swift 6 conventions (per CLAUDE.md)

- `throws(SwiftiomaticError)` typed throws.
- Each migrated rule's body is reviewed for: no `.parent` reads, no `.previousToken` / `.nextToken` reads, single write surface.
- If a candidate rule actually does need broader access, it stays in the catch-all and gets a `// note: not pass-1 because <reason>` comment in its source for future readers.

## Acceptance

- `xc-swift swift_diagnostics` passes.
- `xc-swift swift_package_test` passes (including golden-corpus harness — byte-identical output required).
- `RewriteCoordinatorPerformanceTests` shows a measurable wall-clock drop. Document the before/after numbers in the commit message.
- `PassManifest.md` updated and committed.

## Blocked by

- Multi-pass driver + `Generator` codegen (sibling issue).

## Follow-up

Once this lands and is stable, create per-pass migration issues for:

- pass 2: expression-local
- pass 3: modifier / accessor order
- pass 4: comment / doc
- pass 5: body & wrap
- pass 6: blank lines
- pass 7: structural-but-local
- pass 8: cross-tree structural (each rule solo)
- pass 9: self / type rewrites

Stop when wall-clock target met; remaining rules can stay on the catch-all shelf indefinitely.



## Status note (after `ain-794`)

Infrastructure now in place:
- Marker protocols (`66v-to6`).
- Multi-pass driver + Generator codegen for the catch-all (`ain-794`).
- Golden-corpus byte-identity harness (`m82-uu9`).

What this issue still needs:

1. **Combined-rewriter codegen.** `PassPartitioner` today returns one catch-all `soloPerRule` pass. The combined-rewriter codegen path (`GeneratedPass.Kind.combined`) is stubbed in `PipelineGenerator` but not implemented — for pass 1 to actually combine N rules into one walk, the generator must emit a `final class CombinedPass1Rewriter: SyntaxRewriter` that overrides `visit(_:)` for each unique node kind in the pass and threads the (possibly-rewritten) node through every member rule. The cleanest API is to cache rule instances at init and call `ruleX.visit(node)` in each override (safe for token leaves; for non-leaf nodes it re-walks the subtree but is still correct).

2. **Audit candidate rules.** A spot check of plausible candidates revealed that most read more than one token:
   - `RedundantBackticks` reads `token.parent`, `token.previousToken(...)` — not token-local.
   - `LeadingDotOperators` uses `nextToken` and stateful instance vars — not token-local.
   - `NoSemicolons` reads sibling items via `CodeBlockItemListSyntax` — not token-local.
   - `UppercaseAcronyms` IS token-local but is opt-in (`rewrite: false, lint: .no`) so it doesn't fire by default — migrating it provides no perf win.
   - `PreferFileID` is node-local (visits `MacroExpansionExprSyntax`) and opt-in.

   The next attempt should walk the full 137-rule list with a checklist (no `.parent`, no `previousToken`/`nextToken`, no instance state, single token write surface) and identify the actual short list. The list may be smaller than the issue assumed.

3. **Decide how to handle node-local-but-cheap rules.** If pass 1 ends up with very few token-only rules, the perf win is small. Consider whether `NodeLocalFormatRule` rules (bigger candidate pool) should also share the first combined walk despite the issue scoping pass 1 to token-only.

Gap is documented; reset to ready for a fresh attempt with this context.
