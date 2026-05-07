---
# q3b-eeq
title: Honor Swift's @diagnose attribute for finding suppression and severity (SwiftWarningControl integration)
status: completed
type: feature
priority: normal
created_at: 2026-05-07T16:08:54Z
updated_at: 2026-05-07T16:34:55Z
sync:
    github:
        issue_number: "641"
        synced_at: "2026-05-07T16:36:21Z"
---

Adopt swift-syntax's `SwiftWarningControl` module so Swiftiomatic recognizes the first-party `@diagnose` (formerly `@warn`) attribute as a suppression and severity-control mechanism, in parallel with our existing `// sm:ignore` directives and per-rule JSON config.

## Background

The Swift compiler is gaining a `@diagnose` attribute (renamed from `@warn` in swift-syntax #3305 / commit `0dd94af0`, surfaced via `/cite review` 2026-05-07). It lets users scope diagnostic-group behavior to a lexical region:

```swift
@diagnose(Deprecate, as: error)
func foo() {
  @diagnose(Deprecate, as: warning)
  func bar() {
    @diagnose("Deprecate", as: ignored, reason: "explanation")
    func baz() { … }
  }
}
```

`SwiftWarningControl` (in swift-syntax) adds:
- `SyntaxProtocol.warningGroupControl(for: diagnosticGroupID) -> WarningGroupControl?` — walks parent scopes to compute the effective `.error` / `.warning` / `.ignored` at a node.
- `SyntaxProtocol.warningGroupControlRegionTree` — a precomputed range tree for fast point-in-source lookups.

## Why we want this

1. **Unified suppression vocabulary.** Today users suppress Swiftiomatic findings with `// sm:ignore <rule>` (handled by `RuleMask`). That's parallel to and ignorant of `@diagnose`. With this integration, `@diagnose(<rule-group>, as: ignored)` over a decl silences our findings inside it — same syntax users already use for compiler-side warnings.

2. **Per-region severity control.** A user can upgrade a rule from warn → error in a hot spot, or down to ignored in a tolerated legacy region, without touching config.

3. **Ecosystem alignment.** As `@diagnose` spreads through real codebases (Apple's own libraries, community projects), Swiftiomatic should respect it rather than fight it.

## Scope

- [x] Add `swift-syntax`'s `SwiftWarningControl` product to `Package.swift` dependencies (already in our resolved swift-syntax — verify product name and visibility).
- [x] Each rule declares a stable `diagnosticGroupID: String` (default = rule name; override allowed). This is the identifier `@diagnose(<id>, as: …)` matches against.
- [x] Extend `Context` (or `RuleMask`) with `effectiveSeverity(for rule: SyntaxRule.Type, at node: some SyntaxProtocol) -> Severity` that consults `warningGroupControl(for:)` first, falling back to existing `RuleMask` and JSON config.
- [x] `diagnose(_:on:…)` consults the resolved severity. `.ignored` drops the finding; `.error` upgrades; `.warning` keeps default.
- [x] Tests: a rule emitting a finding is silenced by `@diagnose(<group>, as: ignored)` on the enclosing function/type/extension, and is upgraded to error by `as: error`.
- [x] Doc the precedence: `@diagnose` (most specific scope) > `// sm:ignore` (line-local) > config (file/global) — covered by inline doc comments on `Context.warningControlSeverity` and `WarningControlMask`.

## Open questions

- Group-ID naming: kebab-case (`drop-redundant-escaping`) vs camelCase (`DropRedundantEscaping`)? Compiler-side groups appear to be capitalized identifiers (e.g. `Deprecate`); align with that.
- Do we want to support the `reason:` argument by surfacing it in `Finding.Note`s when the finding is upgraded to error? (Likely yes — useful triage signal.)
- Should `@diagnose` regions also affect format rule rewrites, or only lint findings? Probably lint-only at first; rewrites have different semantics.

## Origin

Filed as a follow-up of `bbx-tyo` (HIGH cite review on 2026-05-07). Swiftiomatic does not currently consume `SwiftWarningControl` — search of `Sources/`, `Package.swift`, `Package.resolved` returned zero references.



## Summary of Changes

Integrated swift-syntax's `SwiftWarningControl` module so Swiftiomatic now honours the first-party `@warn(<group>, as: error|warning|ignored)` attribute (the `@diagnose` rename is on an unreleased swift-syntax branch and not yet in 603.0.1 or 604 prereleases — the integration is spelling-agnostic from our side).

### Files
- `Package.swift` — added `SwiftWarningControl` product to `SwiftiomaticKit`.
- `Sources/SwiftiomaticKit/Syntax/WarningControlMask.swift` (new) — `Lint(WarningGroupControl)` mapping, lazy region-tree cache slot, `Context.warningControlSeverity(of:at:)` helper, `WarningControlMask.diagnosticGroupIdentifiers(forRuleKey:)` candidate-ID generation (tries both `dropRedundantEscaping` and `DropRedundantEscaping`).
- `Sources/SwiftiomaticKit/Support/Context.swift` — store `sourceFileSyntax` for the lazy tree; hold the cache slot.
- `Sources/SwiftiomaticKit/Syntax/SyntaxRule.swift` — `emitFinding` now consults `Context.warningControlSeverity` before emission. If a `@warn` region covers the finding's anchor, that severity wins (`ignored → drop`, `warning → .warn`, `error → .error`); otherwise the configured severity stands. The configured-active gate runs first, so a rule turned off in JSON config stays off — `@warn` cannot re-enable.
- `Tests/SwiftiomaticTests/Core/WarningControlTests.swift` (new) — seven tests driving the real lint pipeline with `DropRedundantEscaping`: default severity, ignored/error/warning by PascalCase ID, ignored by camelCase ID, nested-scope innermost-wins, configured-off-stays-off.

### Behaviour
- Region tree is built lazily once per file on first lookup; files with no findings never pay for it.
- `// sm:ignore` is unchanged and continues to gate upstream of diagnose.
- Format rewrites (`shouldRewrite`) intentionally unaffected — `@warn` only narrows or upgrades emitted findings.
- All 3221 existing tests continue to pass.
