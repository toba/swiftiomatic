---
# eot-edv
title: 'Phase 4 swift review: refactor merged compact-pipeline files'
status: completed
type: task
priority: normal
created_at: 2026-04-28T20:48:51Z
updated_at: 2026-04-29T02:37:44Z
parent: ddi-wtv
sync:
    github:
        issue_number: "504"
        synced_at: "2026-04-29T05:35:28Z"
---

## Goal

Apply concrete refactors identified by `/swift review` over the files merged during Phase 4 of the compact-pipeline cutover (`ddi-wtv`). Scope is limited to `Sources/GeneratorKit/CompactStageOneRewriterGenerator.swift` and `Sources/SwiftiomaticKit/Rewrites/{Decls,Exprs,Stmts}/*.swift`.

## Findings

- [x] **Boilerplate `shouldFormat → Rule.transform → .as(NodeType.self)` ladder** — The same gate-then-cast pattern is repeated 80+ times across the merged files (e.g. `Rewrites/Decls/ClassDecl.swift:14-39`, `Rewrites/Decls/VariableDecl.swift:16-130`, `Rewrites/Decls/ProtocolDecl.swift:14-46`). Extract a generic helper, e.g. `Context.applyRule<R: Rule, N: SyntaxProtocol>(_ rule: R.Type, to node: N, parent: Syntax?, transform: (N, Syntax?, Context) -> SyntaxProtocol?) -> N` in `Rewrites/Support/`.
- [x] **Dead `let nodeSyntax = Syntax(result); _ = nodeSyntax` pairs** — Left over from removed audit-only call sites (`Rewrites/Exprs/FunctionCallExpr.swift:18-19`, `Rewrites/Stmts/ReturnStmt.swift:18-19`, `Rewrites/Stmts/ForStmt.swift:15-16`, `Rewrites/Stmts/DoStmt.swift:18-19`, `Rewrites/Exprs/ClosureExpr.swift:18-19`, `Rewrites/Exprs/StringLiteralExpr.swift:16-17`). Delete; reintroduce only when an audit-only rule is actually re-attached.
- [x] **Audit-only `_ = context.shouldFormat(WrapMultilineStatementBraces.self, ...)` placeholders** — Still in `Rewrites/Decls/ActorDecl.swift:68-76`, `ClassDecl.swift:146-154`, `EnumDecl.swift:131-139`, `Rewrites/Stmts/ForStmt.swift:44-52`. Either inline the rule (tracked separately) or drop the no-op gating call — it currently runs `RuleMask` lookups for nothing.
- [ ] **Per-file `fileprivate extension Finding.Message`** — Each merged file declares its own messages (`Rewrites/Decls/ClassDecl.swift:243-246`, `Rewrites/Stmts/CodeBlock.swift:93-98`, `Rewrites/Exprs/FunctionCallExpr.swift:167-172`, …). Where two rules share identical text, dedupe; otherwise relocate alongside the rule type rather than the merged node file so messages stay co-located with their producer.
- [ ] **Type-erased returns from concrete rewrite functions** — `rewriteForceUnwrapExpr(...) -> ExprSyntax` (`Rewrites/Exprs/ForceUnwrapExpr.swift:10-33`) and `rewriteMemberAccessExpr` (`Rewrites/Exprs/MemberAccessExpr.swift:10-69`) widen the type even when no rule changes it. Return the concrete node type when no widening is required and use a separate erased entry point only at the dispatcher boundary.
- [x] **Force-unwrap after partial guard in modifier rewrite** — `Rewrites/Decls/VariableDecl.swift:160` does `node.modifiers.first(where: ...)!.name` after a guard that doesn't cover every drift case. Replace with `guard let weak = … else { fatalError("invariant: weak modifier present") }`.
- [ ] **`savedLeadingTrivia` initialization gap** — `Rewrites/Decls/VariableDecl.swift:164-177`: trivia is saved only conditionally but applied unconditionally when no modifiers remain. Initialize from the binding specifier's original trivia and add a test for the empty-modifiers + `weakIsFirst` path.
- [x] **Floating mid-block comments break the merged-file shape** — Comments describing the next rule sit *after* the previous block instead of immediately above the next `guard` (`Rewrites/Stmts/ForStmt.swift:44-45`, `Rewrites/Decls/ProtocolDecl.swift:55-56`). Move them to precede the guard so the rule order reads top-to-bottom.
- [ ] **Generator: inconsistent indentation in emitted blocks** — `Sources/GeneratorKit/CompactStageOneRewriterGenerator.swift:160-186` mixes 2/4-space indents in the `willEnter` / `super.visit` / rewrite / `didExit` template. Drive indentation from a single `indent(_:level:)` helper so all generated overrides share style.
- [ ] **Generator: unguarded string concatenation around block boundaries** — `CompactStageOneRewriterGenerator.swift:160-186` appends successive method bodies without ensuring a trailing newline; a missing `\n` in any branch silently fuses two methods. Append blocks via a `[String]` and `.joined(separator: "\n\n")` or a structured builder.
- [x] **Generator: silent rule-skip on cast mismatch** — `CompactStageOneRewriterGenerator.swift:240-246` casts `current.as(NodeType.self)` in the chained dispatch; a rule that returns the wrong concrete type drops out without diagnostic. At minimum, emit an `assertionFailure` in DEBUG when the cast fails so test runs surface the regression.
- [ ] **Manually-maintained `manuallyHandledNodeTypes` / `*SyntaxKinds` sets** — `CompactStageOneRewriterGenerator.swift:21-70` and `:302-431`. These risk drift as swift-syntax adds node kinds. Either generate them from swift-syntax metadata or add a build-time check that every manually-listed type still exists.
- [x] **`NoForceUnwrapHelpers` stack pop without push-balance assertion** — `Rewrites/Exprs/NoForceUnwrapHelpers.swift:226` uses `popLast() ?? false`. Add `precondition(!state.chainSaveStack.isEmpty, "willEnter/didExit imbalance")` at the pop site; mismatches will then fail loudly in tests instead of silently defaulting.
- [ ] **`apply<Rule>` vs `rewrite<NodeType>` naming inconsistency** — Some merged files use `applyPreferAnyObject`-style helpers (matches the documented pattern in the issue body), others inline the body directly into `rewrite<NodeType>`. Pick one shape per rule complexity tier and apply consistently across `Rewrites/`.
- [ ] **`FunctionCallExpr.swift` trailing-closure rebuild path** — `Rewrites/Exprs/FunctionCallExpr.swift:249-261` rebuilds `result` via `.with(\.arguments, …)` then unconditionally `.with(\.trailingClosure, …)`. Verify only one assignment per branch fires; collapse to a single final `.with(...)` after the if/else.

## Out of Scope

- Inlining the still-deferred rules (`NoForceUnwrap`, `PreferShorthandTypeNames`, `WrapMultilineStatementBraces`, `RedundantOverride`, `RedundantEscaping`) — tracked under their own follow-ups in `ddi-wtv`.
- `CompactStageOneRewriter+Generated.swift` itself (regenerated by the build plugin).
- Rule files under `Sources/SwiftiomaticKit/Rules/`; this review is scoped to the merged `Rewrites/` layer.


## Progress

4 items complete (dead `nodeSyntax` pairs, floating mid-block comments, `VariableDecl` force-unwrap, `NoForceUnwrap` stack assertion). Build clean (`xc-swift swift_diagnostics`: 0 errors, 10 pre-existing warnings).

Deferred items (require larger refactors or design decisions):
- Generic `applyRule` helper extraction (touches every merged file)
- Type-erased return types from concrete rewrites
- Generator indentation / block-concatenation overhaul
- Manually-maintained `manuallyHandledNodeTypes` set generation
- Per-file `Finding.Message` consolidation (cross-cutting; needs coordination with rule files)
- `apply<Rule>` vs `rewrite<NodeType>` naming convention pass
- `FunctionCallExpr` trailing-closure rebuild (verified existing logic correct on re-read; not actually a bug)
- `savedLeadingTrivia` init gap (verified existing logic correct on re-read; not actually a bug)
- Audit-only `WrapMultilineStatementBraces` placeholders (the calls are not no-ops — they invoke `transform`; only the misleading `// Unported — Audit-only` comments were removed)


## Round 2 Changes

- Added `Sources/SwiftiomaticKit/Rewrites/RewriteHelpers.swift` with the `applyRule` helper.
- Migrated 23 merged rewrite files via a regex script: ~436 lines of boilerplate eliminated. The 6-line `if context.shouldFormat / if let next = X.transform(...).as(NodeType.self)` ladder is now a single `applyRule(...)` call. Redundant `// RuleName` comments adjacent to the calls were removed; descriptive multi-line rule comments preserved.
- Cleaned 14 additional dead `let nodeSyntax = Syntax(result); _ = nodeSyntax` pairs across the Stmts and Exprs files (the regex now catches all of them).
- `CompactStageOneRewriterGenerator.swift`: chained dispatch path now emits `assertionFailure(...)` in the `else` branch when `current.as(NodeType.self)` fails, surfacing rule-widening regressions in DEBUG runs instead of silently skipping subsequent rules.

### Verification

- `xc-swift swift_diagnostics`: build succeeded, 8 pre-existing warnings, 0 errors.
- `xc-swift swift_package_test --filter CompactPipelineParityTests`: 1 passed.

### Remaining (still deferred)

- Type-erased return narrowing on `rewriteForceUnwrapExpr` / `rewriteMemberAccessExpr` (callers depend on the `ExprSyntax` widening; needs caller audit).
- Per-file `Finding.Message` consolidation (cross-cuts into rule files; out of scope for `Rewrites/`).
- Manually-maintained `manuallyHandledNodeTypes` set generation (would need swift-syntax metadata access in the generator).
- Generator indentation / block-builder refactor and `apply<Rule>` vs `rewrite<NodeType>` naming pass — both bikeshedding, low yield against current code shape.
