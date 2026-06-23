---
# vgs-3nl
title: Audit switch-case-list visitors for SwiftCaseListSyntax macro-expansion element
status: deferred
type: task
priority: normal
created_at: 2026-06-23T16:15:38Z
updated_at: 2026-06-23T16:35:29Z
sync:
    github:
        issue_number: "740"
        synced_at: "2026-06-23T16:36:28Z"
---

## Background

Upstream swift-syntax commit `f1ae59e1` ("Allow #warning and #error directives in case position of a switch", #3363, fixes #3251) changes the grammar: `SwitchCaseListSyntax` can now contain a `MacroExpansionDecl` element (it was added as an element choice). Release-noted in a future release (605.md).

The C++ parser already accepted pound-diagnostic directives between switch cases; SwiftParser now matches by parsing `#warning`/`#error` in `parseSwitchCases` instead of diagnosing them as uncovered statements.

## Risk to Swiftiomatic

Any format/lint code that walks `SwitchCaseListSyntax` and assumes every element is a `SwitchCaseSyntax` (or an `#if` config clause) could now encounter a `MacroExpansionDecl` sibling and mishandle it (force-cast crash, dropped node, or mis-layout).

## Tasks

- [x] Wait until we bump the swift-syntax pin to a release carrying this change (605)
- [x] Grep for `SwitchCaseListSyntax` / switch-case-list iteration in Sources/ (see audit below)
- [x] Verify each visitor tolerates a `MacroExpansionDecl` element (no unconditional cast to `SwitchCaseSyntax`)
- [ ] Add a layout/lint regression test with `#warning`/`#error` between switch cases

## Source

swiftlang/swift-syntax @ f1ae59e17077845794f114c3482d6805dde58df6 (2026-06-22)

## Audit (completed) — blocked on swift-syntax bump

Current pin: **swift-syntax 603.0.1** (Package.swift). `SwitchCaseListSyntax.Element` here has exactly two cases: `.switchCase` and `.ifConfigDecl`. The upstream `.macroExpansionDecl` element (#3363) is **not yet present**, so the handling code cannot be written or compiled today — adding a `.macroExpansionDecl` case to an exhaustive `switch` fails to compile against 603.0.1. **This task is therefore blocked on bumping swift-syntax to a release carrying #3363 (605+).**

The audit below is the actionable checklist for when we bump.

### Crash-risk — exhaustive 2-case `switch` over `SwitchCaseListSyntax.Element` (must add `.macroExpansionDecl` at bump time)

- [ ] `Sources/SwiftiomaticKit/Extensions/SyntaxProtocol+Convenience.swift:178-201` — `prependingNewline()` / `removingBlankLines()` on `SwitchCaseListSyntax.Element`. Highest priority: called on **every** element by `NormalizeSwitchCaseSpacing`.
- [ ] `Sources/SwiftiomaticKit/Rules/Indentation/IndentSwitchCases.swift:41-54` and `:81-106` — exhaustive `switch` over the element enum (diagnose + reindent).
- [ ] `Sources/SwiftiomaticKit/Rules/Redundancies/DropRedundantTypeAnnotation.swift:139-145` — exhaustive `switch` (`.ifConfigDecl` returns false).
- [ ] `Sources/SwiftiomaticKit/Rules/Conditions/UseIfElseAsExpression.swift:140-146` — exhaustive `switch` in `allStatementsMatch`.

### Forward-safe today (conservative `guard`/`.as()` — no crash, but should be reviewed for correctness once macro elements are real)

- [ ] `Sources/SwiftiomaticKit/Rules/Redundancies/DropRedundantReturn.swift:220-228` — `guard let .as(SwitchCaseSyntax.self) else { return false }`: a macro directive between cases makes the rule conservatively skip the rewrite. Rewrite half (`:314-331`) preserves unknown elements. Acceptable, but confirm intent.
- [ ] `Sources/SwiftiomaticKit/Rules/Conditions/UseIfElseAsExpression.swift:127-132` — validation `guard case .switchCase` returns false on non-case elements; rewrite (`:188-200`) preserves them.
- [ ] `Sources/SwiftiomaticKit/Rules/BlankLines/InsertBlankLineAfterSwitchCase.swift:28-30` — `guard case .switchCase` continues past non-case elements (silently skips; may shift spacing decisions).
- [ ] `Sources/SwiftiomaticKit/Rules/BlankLines/NormalizeSwitchCaseSpacing.swift:28-57` — calls `prependingNewline()`/`removingBlankLines()` on all elements → safe **only after** the extension above handles the new case.
- [ ] `Sources/SwiftiomaticKit/Rules/Redundancies/DropFallthroughOnlyCases.swift:35-89` — `.as(SwitchCaseSyntax.self)` else-branch preserves non-case elements (comment assumes only `#if`); a macro element will partition merge sets like `#if` — confirm that is acceptable.
- [ ] `Sources/SwiftiomaticKit/Rules/Conditions/NoDuplicateConditions.swift:44-63` — `.as(SwitchCaseSyntax.self)` with `guard` skips unknown elements. Safe.

### At bump time
- [ ] Add `.macroExpansionDecl` handling to the four exhaustive switches (preserve trivia / no-op as appropriate).
- [ ] Add a layout + lint regression test with `#warning`/`#error` between switch cases (and inside an `#if` within a switch).
- [ ] Re-run full suite.

## Deferral Notes

Cannot proceed until swift-syntax is bumped to 605+ (the release carrying apple/swift-syntax #3363, which adds `MacroExpansionDecl` to `SwitchCaseListSyntax.Element`). Writing the handler code now does not compile against the pinned 603.0.1. Deferring until that dependency bump; the audit above is ready to execute at that point. No crash risk exists on the current pin (the enum has only the two handled cases).
