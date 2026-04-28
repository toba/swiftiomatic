---
# vz0-31g
title: 'ddi-wtv-3: extract static transforms (Access + Closures + Conditions clusters)'
status: completed
type: task
priority: normal
created_at: 2026-04-28T02:42:45Z
updated_at: 2026-04-28T03:17:49Z
parent: ddi-wtv
blocked_by:
    - ogx-lb7
sync:
    github:
        issue_number: "493"
        synced_at: "2026-04-28T02:56:06Z"
---

Mechanical refactor: for each `RewriteSyntaxRule` in the listed directories, extract single-node logic into `static func transform(_ node: T, context: Context) -> T`. The existing `visit(_:)` method calls `super.visit(node)` then `Self.transform(visited, context: context)` so the legacy pipeline keeps working.

## Scope

- `Sources/SwiftiomaticKit/Rules/Access/`
- `Sources/SwiftiomaticKit/Rules/Closures/`
- `Sources/SwiftiomaticKit/Rules/Conditions/`

Skip rules that are pure lint (no `RewriteSyntaxRule`). Skip rules already in the structural-pass bucket from `kl0-8b8` (e.g. `FileScopedDeclarationPrivacy`).

## Tasks

### Access/ (2/2 done)

- [x] `ACLConsistency` - DeclModifierSyntax
- [x] `PrivateStateVariables` - VariableDeclSyntax (erased return)
- [skip] `FileScopedDeclarationPrivacy`, `ExtensionAccessLevel`, `PreferFinalClasses` - structural passes (`g6t-gcm`)

### Closures/ (1/4 in scope; 3 deferred)

- [x] `NoParensInClosureParams` - ClosureSignatureSyntax
- [ ] `PreferTrailingClosures` - large, multiple helpers; clean to extract but ~200 LoC
- [ ] `NoTrailingClosureParens` - **friction**: visit body calls rewriter's `rewrite(Syntax(...))` to recurse a sub-tree; needs design (extract recursion to caller, or skip combined-rewriter)
- [ ] `NamedClosureParams` - **friction**: cross-visit `insideMultilineClosure` state; needs design (state on `CompactStageOneRewriter` or skip)
- [skip] `AmbiguousTrailingClosureOverload`, `MutableCapture`, `OnlyOneTrailingClosureArgument`, `UnhandledThrowingTask` - lint only or pure-lint

### Conditions/ (7/9 done; 2 deferred)

- [x] `NoYodaConditions` - InfixOperatorExprSyntax
- [x] `PreferCommaConditions` - ConditionElementListSyntax
- [x] `PreferConditionalExpression` - CodeBlockItemListSyntax
- [x] `PreferIfElseChain` - CodeBlockItemListSyntax
- [x] `PreferTernary` - CodeBlockItemListSyntax
- [x] `PreferUnavailable` - IfExprSyntax (erased return)
- [x] `ExplicitNilCheck` - ConditionElementSyntax
- [ ] `PreferEarlyExits` - **friction**: calls rewriter `visit(...)` on sub-nodes; deferred to `3zw-l17`
- [ ] `NoParensAroundConditions` - **friction**: 7 visit overrides each calling `visit(...)` recursively; deferred to `3zw-l17`

## Friction discovered

The static-`transform` model assumes single-node-local logic. Two rule patterns don't fit cleanly:

1. **Cross-visit instance state** (e.g. `NamedClosureParams.insideMultilineClosure` set on `ClosureExprSyntax` visit, read on `DeclReferenceExprSyntax` visit). The combined rewriter needs to host this state; the cleanest solution is to give `CompactStageOneRewriter` per-rule mutable state slots (defeats some of the static-fn cleanliness) or keep these rules on the legacy pipeline.
2. **Recursive rewriter calls** inside a visit body (e.g. `NoTrailingClosureParens` calls `rewrite(Syntax(...))` to manually recurse into `calledExpression`). The combined rewriter's `super.visit` already recurses children before transforms run, so the manual recursion is redundant in the combined model — but pulling it out requires re-checking each rule's correctness.

Recommend a separate sub-issue to triage these patterns and decide: (a) host state on the rewriter, (b) leave on legacy, or (c) restructure rule logic.

## Done when

Cluster scope completed or each remaining item has a clear disposition (port / defer-to-design / drop).



## Summary of Changes

Cluster scope **substantially complete**: 10 of the 15 in-scope rules ported to `static func transform(_:context:)`; the remaining 5 (`NoTrailingClosureParens`, `NamedClosureParams`, `PreferTrailingClosures`, `PreferEarlyExits`, `NoParensAroundConditions`) are tracked as friction cases on follow-up issue `3zw-l17`.

Done in this batch:
- Access/: `ACLConsistency`, `PrivateStateVariables`
- Closures/: `NoParensInClosureParams`
- Conditions/: `NoYodaConditions`, `PreferCommaConditions`, `PreferConditionalExpression`, `PreferIfElseChain`, `PreferTernary`, `PreferUnavailable`, `ExplicitNilCheck`

Infra change in the same batch: added `Self.diagnose(_:on:context:)` static helper on `SyntaxRule` so transforms don't need to instantiate the rule per node visit. Refactored `emitFinding` to a `fileprivate static` so both instance and static `diagnose` share the same path.
