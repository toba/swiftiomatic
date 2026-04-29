---
# xyj-vxl
title: 'Phase 4g remainder: delete RewriteSyntaxRule base + 122 rule shells'
status: ready
type: task
priority: high
created_at: 2026-04-29T01:05:14Z
updated_at: 2026-04-29T01:21:26Z
parent: ddi-wtv
sync:
    github:
        issue_number: "505"
        synced_at: "2026-04-29T05:35:27Z"
---

Continuation of `dal-dmw` (Phase 4g) for the larger surgery.

## Tasks

- Delete `Sources/SwiftiomaticKit/Syntax/Rewriter/RewriteSyntaxRule.swift`.
- For each of the 122 `final class FooRule: RewriteSyntaxRule<X>` definitions:
  - Replace inheritance with the appropriate static-only conformance (likely a slimmed `SyntaxRule` protocol or a new protocol that exposes only `key`/`defaultValue`/`group`).
  - Remove the legacy instance `override func visit(...)` overrides — they're dead (the compact pipeline only dispatches via the static `transform`/`willEnter`/`didExit` hooks).
  - Keep the static methods; keep `Finding.Message` extensions; keep the configuration value type.
- Update `Sources/GeneratorKit/RuleCollector.swift` to drop legacy rewrite-rule detection paths (`RewriteSyntaxRule` subclass scan); keep lint-rule discovery and the static-hook scan.
- Decide on `SyntaxRule` protocol shape post-cutover. Compact-pipeline rules don't need instance `context` or `init(context:)`. Lint rules still need them (LintPipeline instantiates them). One option: keep `SyntaxRule` as the shared identity protocol (key, defaultValue, group) and split out `SyntaxLintRule` for the instance side.
- Also drop `dil-cew` (legacy rule-shell delete tracking issue) — its scope is absorbed here.

## Verification gates

- `xc-swift swift_diagnostics --build-tests` clean.
- `xc-swift swift_package_test` all green (2 pre-existing `Layout/GuardStmtTests` pretty-printer-idempotency failures are out of scope).
- LOC reduction: ~120 class shells gone, plus `RewriteSyntaxRule`. Target: -3000 LOC.

## Context

Parent: `ddi-wtv`. Sibling done: `dal-dmw` (which landed the smaller flip-default work).



## Update 2026-04-29

Initial wave done in `dal-dmw` (parent issue): 42 trivial-shell overrides stripped + collector loosened.

Remaining work focuses on the 158 non-shell `override func visit` overrides — these require per-rule analysis since the body contains real logic that needs extraction into static helpers before the override can be deleted.
