---
# iqr-ybv
title: 'Port SwiftTestingNamingConventions rule from swift-format #1236'
status: ready
type: feature
priority: normal
created_at: 2026-07-02T19:40:49Z
updated_at: 2026-07-02T19:40:49Z
sync:
    github:
        issue_number: "747"
        synced_at: "2026-07-02T19:43:27Z"
---

Split out from dnd-wao (deferred item 4). Upstream swiftlang/swift-format added a lint-only rule `SwiftTestingNamingConventions` (`d8da499`, PR #1236). Evaluate/port into Swiftiomatic.

## Upstream behavior
Lint-only rule, all options **off by default** (so the rule is a no-op until a user enables one):
- `forbidSuiteWithoutParameters` — flag a redundant `@Suite` with no arguments (any type with `@Test`s is already a suite).
- `forbidSuiteDescription` / `forbidTestDescription` — flag a separate unlabeled string description on `@Suite` / `@Test`.
- `requireRawIdentifierTestNames` — `@Test` function names must be raw identifiers (backtick-wrapped).

Upstream deliberately did NOT add `requireRawIdentifierSuiteNames`.

## Work required (net-new, not a bugfix)
- New `LintSyntaxRule` file under `Sources/SwiftiomaticKit/Rules/` (likely `Naming/` or a Testing group) — no swift.org license header on new files.
- Config struct (nested `swiftTestingNamingConventions` on `Configuration`) with the 4 Bool options defaulting to false, per the rule model.
- Attribute-convenience helpers upstream relies on: `isAttribute(named:inModule:)`, `hasUnlabeledStringDescription`, `AttributeSyntax.isEmpty`, `FunctionDeclSyntax.hasAttribute(_:inModule:)` — check what Swiftiomatic already has vs. what must be added (upstream added `Attributes+Convenience.swift` / `WithAttributesSyntax+Convenience.swift`).
- Generator regen (Pipelines/ConfigurationRegistry/Schema) happens automatically on build.
- Tests mirroring `SwiftTestingNamingConventionsTests.swift`, written test-first.

## Fit consideration
Swiftiomatic already ships several Swift-Testing rules (UseSwiftTestingNames, RequireSuiteAccessControl, DropRedundantSwiftTestingSuite, etc.). Note potential overlap: `forbidSuiteWithoutParameters` vs the existing `DropRedundantSwiftTestingSuite` rule — reconcile before adding to avoid duplicate/competing findings.

Reference: `~/Developer/swiftiomatic-ref/swift-format` commit d8da499067bf13e3a19baa9c5e51a12f30286e16.
