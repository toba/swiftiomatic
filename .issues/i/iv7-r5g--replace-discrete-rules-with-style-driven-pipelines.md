---
# iv7-r5g
title: Replace discrete rules with style-driven pipelines
status: completed
type: epic
priority: high
created_at: 2026-04-28T01:16:14Z
updated_at: 2026-04-30T00:14:39Z
sync:
    github:
        issue_number: "470"
        synced_at: "2026-04-30T00:29:43Z"
---

## Premise

Issue `qm5-qyp` showed that single-file format spends ~95% of wall-clock time inside `RewritePipeline.rewrite()`, sequentially running 137 full-tree `SyntaxRewriter` passes. The constraint forcing this — rules need parent/sibling visibility, which only holds when each rewrite finishes before the next starts — is a consequence of treating each rule as an independent, individually-configurable unit.

This epic flips the model: **don't preserve discrete rules at all.** Define the desired output as a small set of layout parameters plus a chosen **style**, and write one (or a few) pipelines that produce that output directly. Rules become an internal implementation detail of the style, not a public configuration surface.

## Configuration Model

Replace today's ~140 boolean rule toggles + per-rule sub-configs with:

- A handful of universal settings: `lineLength`, `indentation`, `tabWidth`, `respectsExistingLineBreaks`, line-ending, etc.
- A `style` enum. Initial supported value: **`compact`**.

Style names — open question. Beyond `compact`, candidates for the "more vertical / more breathing room" style:

- `airy` — light, spacious; pairs well as the antonym of `compact`.
- `roomy` — plain-spoken, concrete.
- `relaxed` — emphasises easier reading over density.
- `spacious` — descriptive, neutral.

(`expanded` is rejected per the prompt.) Recommend **`airy`** as the second style — short, distinct from `compact` in shape and meaning, doesn't overload an existing technical term.

For this epic only `compact` ships. `airy` is reserved as a name; not implemented.

## Architectural Question

The motivating question: *if discrete rules didn't need to exist, how would we achieve the goals of `qm5-qyp`?*

Working answer — two stages, not 137 passes:

### Stage 1: Syntax normalization (one combined `SyntaxRewriter`)

A single tree walk that performs every node-local syntactic transformation the style demands: modifier order, redundant-self stripping, doc-comment conversion, empty-collection literal canonicalisation, accessor order, semicolon removal, etc. All of today's "format rules that don't need cross-rule ordering" collapse into per-node-kind methods on this rewriter. Parent/sibling visibility is preserved within a single walk by reading from the original tree where needed (the same constraint `LintPipeline` already manages).

Structural reshapers that genuinely need a settled tree (`SortImports`, blank-line policies that depend on prior trivia rewrites, `ExtensionAccessLevel`) run as a small number of follow-up passes — likely 2–3, not 137.

### Stage 2: Pretty-print (existing Oppen layout engine)

Unchanged in shape. The style supplies the layout parameters: line length, break precedence tuning, where `compact` prefers to keep things on one line, where it permits wrapping. The pretty-printer remains the right tool — token streams + Oppen are how you express "fit on a line if you can, otherwise break here first" declaratively. Inventing a non-pretty-printer alternative is not on the table.

The split survives because the two stages do genuinely different things: stage 1 changes *what tokens exist*, stage 2 chooses *where they sit on the page*. Trying to fuse them re-introduces the parent-visibility problem swift-format originally split to avoid.

## What This Replaces

- `Configuration.rules: [String: Bool]` — gone. Style + parameters only.
- Per-rule sub-configs (`orderedImports`, `fileScopedDeclarationPrivacy`, etc.) — folded into the style definition.
- `FormatPipeline` as a sequence of independent `SyntaxFormatRule` rewriters — gone. Replaced by the style's normalization rewriter + small fixed list of structural passes.
- `Pipelines+Generated.swift` rewrite section — gone or radically smaller.
- `--rules`, individually toggleable rule enable/disable — gone from public CLI surface (style choice only).

What stays:

- `SyntaxLintRule` and `LintPipeline` — lint findings remain a separate, interleaved single-walk concern. (Style still drives *which* findings; mechanics unchanged.)
- The pretty printer and `LayoutCoordinator`.
- `Finding` / `Message` / `RuleMask` — `// sm:ignore` still works, but disables findings, not "rules".
- `swift-format` CLI subcommand surface (`format`, `lint`, `dump-configuration`) per CLAUDE.md.

## Performance Implication (the qm5-qyp link)

If stage 1 is one walk plus ≤3 structural passes, the hot loop drops from 137× to ~4× full-tree rewrites. At ~22 ms per pass on a 1k-line file, that's ~90 ms — comfortably under the 200 ms beachball target without any cleverness like node-kind gating. The performance win falls out of the architecture; we don't have to hand-tune it.

## Open Questions / To Audit

- Which of today's format rules are *truly* node-local vs. need a settled tree? Inventory against the existing 137.
- How does `compact` express today's per-rule sub-configs (e.g., `fileScopedDeclarationPrivacy.strict`)? As style-level parameters, or hardcoded into the style?
- Migration of existing `swiftiomatic.json` configs — silently map old rule toggles onto the closest style, or hard-break with a deprecation message?
- Lint side: do we keep individually-toggleable lint rules, or also fold those into the style? Recommendation: keep lint rules toggleable for now — the perf problem is on the format side.
- DocC + `list-rules` output: rules-as-internal-implementation means `list-rules` becomes "list findings" or goes away.
- Does `compact` need to be defined as data (a config struct) or as code (a dedicated rewriter type)? Probably code, given the per-node logic is non-uniform.

## Children

- `kl0-8b8` — Inventory format rules: node-local vs structural vs deletable
- `2kl-d04` — Design `compact` style spec (blocked by `kl0-8b8`)
- `0ev-1u9` — Stub `roomy` style (name reservation only)
- `eti-yt2` — Spike: combined SyntaxRewriter for node-local rules (blocked by `kl0-8b8`)
- `o72-vx7` — Configuration schema redesign: `style` + universal parameters (blocked by `2kl-d04`)
- `e4v-075` — CLI: replace --rules plumbing with --style (blocked by `o72-vx7`)
- `ddi-wtv` — Cut over to `compact` pipeline; delete superseded rule files (blocked by `eti-yt2`, `o72-vx7`, `e4v-075`)
- `0we-lcr` — Update DocC, README, list-rules / generate-docs (blocked by `ddi-wtv`)

Second style is decided: **`roomy`** (stubbed only — name reserved, no implementation in this epic).

## Out of Scope

- Implementing `airy` (or whichever second style is chosen). Reserve the name; defer the work.
- Daemon mode (still a separate concern).
- Lint rule reorganization.



## Considerations (refinement)

### Lints stay discrete

Lints already run through `LintPipeline` — the single-walk interleaved model the format side is moving *toward*. The `qm5-qyp` perf problem is format-only. Keep discrete lint rules; tidy the config shape:

```json
"lints": {
  "naming": { "AlwaysUseLowerCamelCase": "error", "AvoidNoneName": "warn" },
  "spacing": { "NoLeadingWildcardImports": "off" }
}
```

Tri-state `off|warn|error` replaces today's `Bool` — folds severity into the toggle. For the few rules with extra config (e.g. `orderedImports.groupByKind`), nested form: `{ "OrderedImports": { "severity": "warn", "groupByKind": true } }`. Default to the bare string form.

### File organization — secondary goal

The combined stage-1 `SyntaxRewriter` doesn't have to be a single megafile. Make it a thin dispatcher whose `visit(_:)` overrides delegate to free functions / extension methods organised by aspect, mirroring today's `Sources/SwiftiomaticKit/Rules/<Group>/` layout (`Modifiers.swift`, `Comments.swift`, `EmptyLiterals.swift`, etc.). Same per-file logic, called inside one walk instead of one-rewriter-per-rule. Zero perf cost — static calls into extension methods are cheaper than instantiating a `SyntaxRewriter` per rule.

Performance stays top priority; this just preserves discoverability.



## Summary of Changes (epic closure)

All 13 child issues are completed or scrapped:

- `kl0-8b8` — Inventory format rules: node-local vs structural vs deletable. completed.
- `2kl-d04` — Design `compact` style spec. completed.
- `0ev-1u9` — Stub `roomy` style (name reservation only). completed.
- `eti-yt2` — Spike: combined SyntaxRewriter for node-local rules. completed.
- `o72-vx7` — Configuration schema redesign: `style` + universal parameters. completed.
- `e4v-075` — CLI: replace --rules plumbing with --style. completed.
- `ddi-wtv` — Cut over to compact pipeline; delete superseded rule files. completed.
- `wru-y41` — Collapse compact-pipeline rule shells into pure helpers. completed.
- `6ji-ue3` — Drop applyRule + shouldFormat gating; push selection/sm:ignore checks out. completed.
- `c6i-b47` — Replace metatype-keyed Context.ruleState(for:) with typed state properties. completed.
- `2uk-cll` — Rename RewriteSyntaxRule to StructuralFormatRule; hoist gating to dispatcher. completed.
- `edy-7hr` — Make compact-style rewrites always-on; remove Configuration.isActive from rewrite path. scrapped.
- `0we-lcr` — Update DocC, README, list-rules / generate-docs for style model. completed.

### Final pipeline shape

- Stage 1: `CompactStageOneRewriter` — single tree walk dispatching every `StaticFormatRule` (`willEnter` → `super.visit` → `rewrite<NodeType>` → `didExit`).
- Stage 2: ≤9 `StructuralFormatRule` passes (`SortImports`, blank-line policy, `ExtensionAccessLevel`, `FileScopedDeclarationPrivacy`, `FileHeader`, `CaseLet`, …).
- Pretty-print: unchanged Oppen-style `LayoutCoordinator`.

### Configuration

- `style` enum (`compact` default, `roomy` reserved) + universal layout settings drive formatting.
- Lint side stays per-rule (`"lint": "no" | "warn" | "error"`).
- `--style` CLI flag overrides the configured style for a single invocation.

### Performance

- `testFullFormatPipelinePerformance`: 4.7s (legacy) → ~0.32s — ~14× speedup, well under the 200 ms target.

### Test surface

- 3008 pass / 2 pre-existing `Layout/GuardStmtTests` pretty-printer-idempotency failures (predate this epic, unrelated).

### Out of scope (deferred)

- Implementing `roomy`.
- Eliminating the `StructuralFormatRule` base class.
- Migrating remaining `RuleCollector` legacy detection paths.

The doc-update task (`0we-lcr`) closed out the user-facing surface: README, sub-target READMEs, `CLAUDE.md`, and removal of the dead `DocumentationGenerator.swift`.
