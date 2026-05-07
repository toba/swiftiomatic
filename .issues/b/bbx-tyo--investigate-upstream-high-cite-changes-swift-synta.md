---
# bbx-tyo
title: Investigate upstream HIGH cite changes (swift-syntax @warn→@diagnose, SwiftLint tuple taint + unused_imports access levels)
status: completed
type: task
priority: normal
created_at: 2026-05-07T15:52:24Z
updated_at: 2026-05-07T16:13:27Z
blocking:
    - q3b-eeq
sync:
    github:
        issue_number: "640"
        synced_at: "2026-05-07T16:13:56Z"
---

Review high-relevance upstream changes surfaced by `jig cite review` on 2026-05-07 and decide whether Swiftiomatic needs to follow.

## swiftlang/swift-syntax

- [x] `0dd94af0` — [Source Warning Control] Rename `@warn` to `@diagnose` (#3305)
  - Files: `Sources/SwiftWarningControl/{SyntaxProtocol+WarningControl,WarningControlDeclSyntax,WarningControlRegionBuilder,WarningControlRegions}.swift`
  - Check whether Swiftiomatic references `@warn` / `WarningControl` API surface; if so, migrate to `@diagnose`.

## realm/SwiftLint

- [x] `767d780c` — Taint variables in tuples (#6629)
  - Files: `UnneededEscapingRule.swift`, `UnneededEscapingRuleExamples.swift`
  - Compare against any equivalent escaping/unused-variable rule in Swiftiomatic; port test cases if they expose gaps.
- [x] `33430347` — Support access level modifiers on imports in `unused_imports` (#6631)
  - Files: `UnusedImportRule.swift`, `UnusedImportRuleExamples.swift`
  - Verify Swiftiomatic's unused-import handling correctly classifies `public import` / `package import` / `internal import` etc.

## Acceptance

- For each item above: either land a follow-up change or note in this issue why no action is needed, then mark the checkbox.



## Summary of Changes

### swift-syntax `@warn` → `@diagnose` (no-op today; follow-up filed)

Swiftiomatic does not consume `SwiftWarningControl` — zero references in `Sources/`, `Package.swift`, or `Package.resolved`. No migration needed. Filed `q3b-eeq` (feature) to track first-class adoption: rules declare a stable diagnostic-group ID, `Context` resolves effective severity from `@diagnose` regions, finding suppression and severity-upgrade flow through the attribute alongside our existing `// sm:ignore` directives.

### SwiftLint #6629 — taint variables in tuples (real bug, fixed)

Our `DropRedundantEscaping` rule had a false-positive bug: `EscapeChecker` only tracked `IdentifierPatternSyntax` bindings and treated `TupleExprSyntax` as opaque. Closures escaping via tuple — `inner(tuple: (closure, 42))`, `let (local, _) = (completion, 17); self.local = local`, etc. — were not detected, so the rule would have suggested dropping a load-bearing `@escaping`.

Fix: extended `EscapeChecker` in `Sources/SwiftiomaticKit/Rules/Redundancies/DropRedundantEscaping.swift`:
- `isTainted(_:)` recognizes `TupleExprSyntax` (tainted if any element is tainted).
- New `registerPattern(_:sourceTainted:)` walks `IdentifierPatternSyntax` and `TuplePatternSyntax` recursively, propagating taint from the initializer.

Added 4 negative-case tests in `Tests/SwiftiomaticTests/Rules/DropRedundantEscapingTests.swift` (passed-in-tuple, destructure-then-escape, whole-tuple-escape, chained destructure) — all initially failed against the unmodified rule, all pass after the fix. Filtered suite 11/11 green, full suite 3214/3214 green.

### SwiftLint #6631 — `unused_imports` access-level support (deferred deliberately)

Swiftiomatic has no `unused_imports` rule and we never explicitly took a position on it during the original SwiftLint port. Appended a full rationale to `81p-a0m` (Rules unlikely to be implemented): the rule fundamentally needs a hard-coded module-symbol catalog, and its failure mode is silent link-time breakage in **downstream** modules — conformance-only modules (`RegexBuilder` provides `String: RegexComponent`), macro-only modules (`Observation`, `SwiftData`), and `@_implementationOnly` imports all look unused textually but are load-bearing. The May-2 `gf3-hxe` near-miss (where Xcode's compiler-fix-it was blamed on swiftiomatic) makes this concrete. If we ever revisit: lint-only (no rewrite), opinionated allowlist of conformance/macro modules, honor access-level modifiers + `@_implementationOnly` from day one, escape-hatch directive.
