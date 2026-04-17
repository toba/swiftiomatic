---
# slo-vvd
title: Extract shared functionality across Swiftiomatic rules
status: completed
type: feature
priority: normal
created_at: 2026-04-15T00:20:13Z
updated_at: 2026-04-17T21:56:40Z
sync:
    github:
        issue_number: "307"
        synced_at: "2026-04-17T22:17:15Z"
---

Extract duplicated patterns across 125 rule files into shared protocols, protocol extensions, and utility types. Estimated ~800-1000 lines of deduplication.

## High Priority

- [x] **TestContextTracker struct** — 6 rules duplicate ~30 lines each of test-scope tracking (`importsTesting`, `insideXCTestCase`, `isTestFunction`, `visit(ImportDeclSyntax)`, `visit(SourceFileSyntax)`, `visit(ClassDeclSyntax)`). Rules: NoForceTry, NoForceUnwrap, NoGuardInTests, LowerCamelCase, NoImplicitlyUnwrappedOptionals, + RedundantSwiftTestingSuite/SwiftTestingTestCaseNames (partial)
- [x] **FunctionDeclSyntax.addingThrowsClause()** — 4 identical `addThrows(to:)` copies (~25 lines each). Rules: NoForceTry:131, NoForceUnwrap:488, NoGuardInTests:440, PreferSwiftTesting:615
- [x] **Trivia blank-line helpers** — 5 rules duplicate `blankLineCount(in:)`, `hasBlankLine(in:)`, `reducedTrivia(_:)`. Add to Trivia+Convenience.swift
- [x] **WithModifiersSyntax.removingModifier(matching:keyword:)** — 8+ rules duplicate modifier removal + trivia transfer pattern

## Medium Priority

- [~] **HoistAwait/HoistTry unification** — deferred permanently: ~40-50 lines net savings after protocol overhead; divergences (try?/try! reordering, extra visit method) are meaningful, not mechanical
- [~] **NamedDeclVisitor protocol** — spun off to dedicated issue; 53 rules, 289 overrides, ~1,135 lines of boilerplate; best done via codegen extension
- [x] **SwitchCaseListSyntax.Element helpers** — `addLeadingNewline(to:)` duplicated in 2 rules
- [~] **Sort rule scaffolding** — deferred permanently: SortImports (689 lines) doesn't fit pattern; remaining 3 rules save ~80 lines but trivia handling varies too much for clean abstraction

## Low Priority

- [x] **TriviaPiece.isSpaceOrTab/isDocComment visibility** — fileprivate in DocCommentsBeforeModifiers, should be shared
- [~] **SourceFileSyntax.collectIdentifiers()** — scrapped: 6 implementations are each specialized (token-level vs scope-aware vs inheritance-clause); generic extension would need heavy parameterization for ~50 lines saved

## Approach

Work incrementally: extract one utility, update consuming rules, build + test, repeat.


## Summary of Changes

Extracted 6 shared utilities, removing ~400 lines of duplicated code across 15+ rule files:

1. **Trivia+Convenience**: `blankLineCount`, `hasBlankLine`, `reducingToSingleNewlines`, `totalNewlineCount`, `replacingFirstNewlines(with:)` — replaced 5 private implementations
2. **FunctionDeclSyntax.addingThrowsClause()** — replaced 4 identical `addThrows(to:)` copies
3. **TestContextTracker** — replaced 3 identical scope-tracking state machines in NoForceTry, NoForceUnwrap, NoGuardInTests
4. **DeclSyntaxProtocol.removingModifiers(_:keyword:)** — replaced manual modifier removal + trivia transfer in NoExplicitOwnership, TestSuiteAccessControl
5. **SwitchCaseListSyntax.Element** extensions (`.prependingNewline()`, `.removingBlankLines()`) — replaced 2 identical helpers
6. **TriviaPiece.isDocComment** promoted to shared — removed fileprivate duplicate from DocCommentsBeforeModifiers
