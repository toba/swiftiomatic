---
# slo-vvd
title: Extract shared functionality across Swiftiomatic rules
status: in-progress
type: feature
priority: normal
created_at: 2026-04-15T00:20:13Z
updated_at: 2026-04-15T00:32:56Z
sync:
    github:
        issue_number: "307"
        synced_at: "2026-04-15T00:34:43Z"
---

Extract duplicated patterns across 125 rule files into shared protocols, protocol extensions, and utility types. Estimated ~800-1000 lines of deduplication.

## High Priority

- [x] **TestContextTracker struct** — 6 rules duplicate ~30 lines each of test-scope tracking (`importsTesting`, `insideXCTestCase`, `isTestFunction`, `visit(ImportDeclSyntax)`, `visit(SourceFileSyntax)`, `visit(ClassDeclSyntax)`). Rules: NoForceTry, NoForceUnwrap, NoGuardInTests, LowerCamelCase, NoImplicitlyUnwrappedOptionals, + RedundantSwiftTestingSuite/SwiftTestingTestCaseNames (partial)
- [x] **FunctionDeclSyntax.addingThrowsClause()** — 4 identical `addThrows(to:)` copies (~25 lines each). Rules: NoForceTry:131, NoForceUnwrap:488, NoGuardInTests:440, PreferSwiftTesting:615
- [x] **Trivia blank-line helpers** — 5 rules duplicate `blankLineCount(in:)`, `hasBlankLine(in:)`, `reducedTrivia(_:)`. Add to Trivia+Convenience.swift
- [x] **WithModifiersSyntax.removingModifier(matching:keyword:)** — 8+ rules duplicate modifier removal + trivia transfer pattern

## Medium Priority

- [ ] **HoistAwait/HoistTry unification** — structural twins but details diverge (try?/try! guard, await reordering); deferred — forced abstraction adds complexity
- [ ] **NamedDeclVisitor protocol** — 104 visit overrides across 31 files fan out to same helper; unified dispatch
- [x] **SwitchCaseListSyntax.Element helpers** — `addLeadingNewline(to:)` duplicated in 2 rules
- [ ] **Sort rule scaffolding** — 4 Sort* rules follow identical algorithm; SortableItemRule protocol

## Low Priority

- [x] **TriviaPiece.isSpaceOrTab/isDocComment visibility** — fileprivate in DocCommentsBeforeModifiers, should be shared
- [ ] **SourceFileSyntax.collectIdentifiers()** — marginal win (Set vs counting Dict, conditional); deferred

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
