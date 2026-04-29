---
# 2tv-v3y
title: Eliminate RewriteSyntaxRule base class
status: draft
type: feature
priority: normal
created_at: 2026-04-29T17:20:17Z
updated_at: 2026-04-29T17:20:17Z
parent: ddi-wtv
sync:
    github:
        issue_number: "508"
        synced_at: "2026-04-29T17:25:06Z"
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
