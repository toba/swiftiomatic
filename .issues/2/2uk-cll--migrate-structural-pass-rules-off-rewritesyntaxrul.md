---
# 2uk-cll
title: Rename RewriteSyntaxRule to StructuralFormatRule; hoist gating to dispatcher
status: completed
type: task
priority: high
created_at: 2026-04-29T22:44:51Z
updated_at: 2026-04-29T23:33:56Z
parent: iv7-r5g
sync:
    github:
        issue_number: "511"
        synced_at: "2026-04-30T00:29:45Z"
---

## Goal

Rename `RewriteSyntaxRule<V>` to `StructuralFormatRule<V>` (sister to `StaticFormatRule<V>` for compact-pipeline rules and `LintSyntaxRule<V>` for lint rules — the trio's purpose becomes obvious). Move gating from `visitAny` (per-node) to `RewriteCoordinator`'s structural-pass dispatcher (per-pass, at file level). Drop the `visitAny` override.

## Why renaming, not deleting

The original `wru-y41` audit framed `RewriteSyntaxRule<V>` as scaffolding to delete. Closer reading shows it's genuinely useful for structural passes — they need both `Rule` registration (`key`, `group`, `defaultValue`) AND `SyntaxRewriter` machinery (`override func visit(_:)`). Deleting the base class would force ~10 rules to repeat the same `let context`, `init(context:)`, `visitAny` shim, and class-var boilerplate. Net code goes up.

The cleanup that's *actually* worth doing is:

1. **Rename** to make the role obvious. `StructuralFormatRule` says exactly what it is.
2. **Hoist gating to the dispatcher.** `visitAny` runs the gate check on every node visited; for structural passes (which act per file or per scope-introducing node), that's wasteful. One check per pass at the dispatcher entry is enough.

## Affected rules

10 inheritors:

- `BlankLinesAfterImports`
- `BlankLinesBetweenScopes`
- `ExtensionAccessLevel`
- `FileHeader`
- `FileScopedDeclarationPrivacy`
- `PreferShorthandTypeNames`
- `SortDeclarations`
- `SortImports`
- `SortSwitchCases`
- `SortTypeAliases`

Plus generic constraint in `LintPipeline.visitIfEnabled<V, Rule: RewriteSyntaxRule<V>, Node>`.

## Plan

1. Rename file `Sources/SwiftiomaticKit/Syntax/Rewriter/RewriteSyntaxRule.swift` → `StructuralFormatRule.swift`.
2. Rename type. Drop the `visitAny` override.
3. Hoist gating to `RewriteCoordinator.runCompactPipeline`: each structural-pass invocation gated by `context.shouldFormat(Foo.self, node: sourceFile)`.
4. Update the 10 inheriting rules' superclass references.
5. Update `LintPipeline.visitIfEnabled` generic constraint.
6. Update doc-comment references throughout.

## Out of scope

- `applyRule` ladder cleanup (`6ji-ue3` — done).
- `Context.ruleState(for:)` typed-property migration (`c6i-b47` — done).
- Public configuration redesign.

## Verification bar

- `xc-swift swift_diagnostics --no-include-lint` clean (11-warning baseline).
- 3,009 tests pass; only the 2 pre-existing pretty-printer-idempotency failures remain.



## Summary of Changes

Renamed `RewriteSyntaxRule<V>` → `StructuralFormatRule<V>` and hoisted per-pass gating from the base class's `visitAny` shim to the structural-pass dispatcher in `RewriteCoordinator`. The base class is now purely registration + context plumbing — no per-node gate check.

### What landed

- **`Sources/SwiftiomaticKit/Syntax/Rewriter/RewriteSyntaxRule.swift`** renamed to `StructuralFormatRule.swift`. Type renamed; `visitAny` override removed.
- **`RewriteCoordinator.runCompactPipeline`** now gates each structural pass at file level via a new private `runStructuralPass(_:on:context:)` helper that calls `context.shouldFormat(R.self, node: node)` once and instantiates+runs the rule only when it would actually fire. Saves N visit-callback invocations per skipped rule.
- **22 `RewriteSyntaxRule` references replaced** with `StructuralFormatRule` across 19 source + 1 test file (rule superclasses, generic constraint in `LintPipeline.visitIfEnabled<V, Rule: StructuralFormatRule<V>, Node>`, configuration registry, doc comments).
- **Doc-comment fix on `Context.shouldFormat(ruleType:node:)`** — no longer references the deleted `visitAny` shim.

### Verification

- `xc-swift swift_diagnostics --no-include-lint` clean (11 warnings, baseline).
- 3,009 tests pass; only the 2 pre-existing pretty-printer-idempotency failures remain.

### Affected rules (all renamed superclass to `StructuralFormatRule`)

`BlankLinesAfterImports`, `BlankLinesBetweenScopes`, `ExtensionAccessLevel`, `FileHeader`, `FileScopedDeclarationPrivacy`, `PreferShorthandTypeNames`, `SortDeclarations`, `SortImports`, `SortSwitchCases`, `SortTypeAliases`.
