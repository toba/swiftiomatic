---
# 2tv-v3y
title: Eliminate RewriteSyntaxRule base class
status: completed
type: feature
priority: normal
created_at: 2026-04-29T17:20:17Z
updated_at: 2026-04-29T18:22:42Z
parent: ddi-wtv
sync:
    github:
        issue_number: "508"
        synced_at: "2026-04-29T22:39:24Z"
---

Follow-up to phase 4g (`dal-dmw`). All in-scope strip work landed; the `RewriteSyntaxRule` base class is now used by:

1. **Structural-pass rules** (10): `SortImports`, `SortTypeAliases`, `SortSwitchCases`, `SortDeclarations`, `BlankLinesAfterImports`, `BlankLinesBetweenScopes`, `ExtensionAccessLevel`, `FileScopedDeclarationPrivacy`, `FileHeader`, `CaseLet`. These genuinely need `SyntaxRewriter` machinery (their `override func visit` IS the rule).
2. **Fresh-instance rule**: `PreferShorthandTypeNames` (recursion into generic arguments is fundamental — see session 20/21 notes on `ddi-wtv`).
3. **~120 static-only rules** that inherit `RewriteSyntaxRule` purely vestigially — they only define `static transform`/`willEnter`/`didExit` and don't override any `visit` method. They could conform to `SyntaxRule` directly without `SyntaxRewriter` baggage.

## Goal

Split `RewriteSyntaxRule` so static-only rules drop the `SyntaxRewriter` inheritance:

- `RewriteSyntaxRule` stays for cases (1) and (2) above (≤11 rules).
- New `StaticFormatRule` protocol (or similar) for case (3).
- `RuleCollector` updated to detect both shapes.
- `PipelineGenerator` and `Configuration`/`ConfigurationRegistry` adapted as needed.

## Why this matters

- Reduces conceptual surface (~120 fewer SyntaxRewriter instances allocated).
- Clarifies the architecture: most "rewrite rules" are now namespace-style static collectors of transform hooks, not actual tree walkers.
- Removes the `init(context:)` / instance-state ceremony from rules that don't need it.

## Out of scope

- Restoring lint-mode finding emission for compact-pipeline-only rules — separate concern (see sibling issue).



## Summary of Changes

Split `SyntaxRule` into a type-level identity protocol plus an `InstanceSyntaxRule` sub-protocol that adds `var context: Context { get }` and `init(context: Context)`. Introduced a new `StaticFormatRule<V>` base class that conforms to bare `SyntaxRule` and carries no `SyntaxRewriter` baggage — it's a pure registration shell for the rule's `key`/`group`/`defaultValue`. Migrated 127 rule classes (the ones that had no `override func visit` on the rule class itself) from `: RewriteSyntaxRule<X>` to `: StaticFormatRule<X>`.

### Architecture

- **`SyntaxRule`** — `Configurable & Sendable where Value: SyntaxRuleValue`. No instance requirements. Provides static `diagnose`, `defaultIsActive`, `emitFinding`.
- **`InstanceSyntaxRule: SyntaxRule`** — adds `var context: Context` and `init(context: Context)`. Conformed to by `LintSyntaxRule` and `RewriteSyntaxRule`. Provides instance `diagnose` and the severity-overload `diagnose`.
- **`StaticFormatRule<V>`** — concrete base class for compact-pipeline-only rules. Inherits nothing other than `SyntaxRule` conformance. Eliminates the `init(context:)` and `var context` ceremony for rules that never instantiate.
- **`RewriteSyntaxRule<V>`** — kept for the 10 structural-pass rules + `PreferShorthandTypeNames` + `RedundantSelf`/`CaseLet` (the latter two have inner private `SyntaxVisitor`/`SyntaxRewriter` helpers but the rule class itself was migrated to `StaticFormatRule`).
- **`LintPipeline.rule<R: InstanceSyntaxRule>(_)`** — generic constraint tightened (was `SyntaxRule`); only instantiable rules are cached.

### Migration

127 rule files batch-edited (`sed 's/RewriteSyntaxRule</StaticFormatRule</g'`). `RuleCollector.detectSyntaxRule` extended to accept `StaticFormatRule` as a third inheritance pattern (`canRewrite = true`).

`assertFormatting` test helper relaxed: was `(some SyntaxRule & SyntaxRewriter).Type`, now `(some SyntaxRule).Type`. The `SyntaxRewriter` constraint was vestigial — the test pipeline always runs through `RewriteCoordinator.format` regardless of whether the rule itself inherits `SyntaxRewriter`.

`NoSemicolons` had two vestigial instance methods (`nodeByRemovingSemicolons`, `isCodeBlockItem`) that referenced `rewrite(...)` (SyntaxRewriter) and `diagnose(...)` (instance) — both unavailable post-migration since the static counterparts already handle the compact pipeline. Removed.

`RewriteCoordinatorPerformanceTests.testFullFormatPipelinePerformance` had four redundant structural-pass entries (`PreferFinalClasses`, `ConvertRegularCommentToDocC`, `ConsistentSwitchCaseSpacing`, `ReflowComments`) whose underlying rules were inlined into stage 1 in earlier sessions; mirroring `runCompactPipeline` cleanup, removed those four `Rule(context:).rewrite(current)` calls.

`CombinedRewriterSpikeTests.testSequentialRewritersPerformance` was a pre-cutover spike comparing legacy-sequential to combined-rewriter. Its rules (`RedundantBreak`, `NoBacktickedSelf`, `RedundantNilInit`) are now `StaticFormatRule` with no `init(context:)`, so the test no longer compiles. Removed — the spike's purpose was satisfied by `ddi-wtv` landing.

### Verification

- `xc-swift swift_diagnostics --no-include-lint`: build clean (12 warnings, down 1).
- `xc-swift swift_package_test`: **3009 pass / 2 fail** (the 2 pre-existing GuardStmt pretty-printer-idempotency failures, unrelated). Three fewer total than session 21's 3012 because the deleted spike test contributed three measurement sub-tests.

### What's still using RewriteSyntaxRule

10 rule files (down from 137):
- Structural-pass rules (10): `SortImports`, `SortTypeAliases`, `SortSwitchCases`, `SortDeclarations`, `BlankLinesAfterImports`, `BlankLinesBetweenScopes`, `ExtensionAccessLevel`, `FileScopedDeclarationPrivacy`, `FileHeader` — `override func visit` IS the rule body; these rules are run as ordered `SyntaxRewriter` instances by `RewriteCoordinator.runCompactPipeline` (stage 2).
- Fresh-instance: `PreferShorthandTypeNames` — recursion into generic-argument children is fundamental.

`RewriteSyntaxRule` cannot be deleted while these 11 rules need `SyntaxRewriter` machinery. Eliminating those is a separate, larger refactor (e.g. inlining structural-pass rules into stage 1 with willEnter/transform hooks, or keeping a dedicated structural-pass base class). Not in scope for this issue.
