---
# 135-dxk
title: 'Cat 2: Redundancy & Cleanup (6 rules)'
status: completed
type: feature
priority: normal
created_at: 2026-04-15T00:27:58Z
updated_at: 2026-04-25T19:33:50Z
parent: qlt-10c
sync:
    github:
        issue_number: "319"
        synced_at: "2026-04-25T19:53:35Z"
---

Remove dead code and unnecessary constructs. Auto-fixable ones → `SyntaxFormatRule`.

| SwiftLint Rule | Swiftiomatic Name | Scope | Description |
|---|---|---|---|
| `redundant_nil_coalescing` | RedundantNilCoalescing | `.format` | `x ?? nil` is redundant |
| `unneeded_override` | RedundantOverride | `.lint` | Override that just calls super with identical args |
| `unused_enumerated` | RedundantEnumerated | `.format` | `.enumerated()` when index or item is unused |
| `unneeded_parentheses_in_closure_argument` | NoParensInClosureParams | `.format` | `{ (x, y) in }` → `{ x, y in }` |
| `redundant_set_access_control` | RedundantSetterACL | `.lint` | Setter ACL same as property ACL is redundant |
| `unneeded_escaping` | RedundantEscaping | `.format` | `@escaping` when closure doesn't actually escape (complex — needs escape analysis) |



## Summary of Changes

All 6 rules implemented as `RewriteSyntaxRule` (auto-fix), each with a comprehensive test suite. Total 43 new tests, all passing individually (combined run blocked by MCP server drop).

### Files added

Rules — `Sources/SwiftiomaticKit/Rules/`:
- `Redundant/RedundantNilCoalescing.swift` — strips `?? nil` from `InfixOperatorExprSyntax`
- `Redundant/RedundantOverride.swift` — removes overrides whose body is just `super.foo(args)` with identical args; skips `setUp`/`viewDidLoad`/etc.
- `Redundant/RedundantEnumerated.swift` — `for (_, x) in seq.enumerated()` → `for x in seq`; `for (i, _) in seq.enumerated()` → `for i in seq.indices` (for-loop scope only; closure $0/$1 case deferred)
- `Redundant/RedundantSetterACL.swift` — drops `(set)` when it matches the property's own access modifier or the enclosing type's effective access
- `Redundant/RedundantEscaping.swift` — removes `@escaping` when the closure demonstrably does not escape (flow-insensitive `EscapeChecker` tracks tainted vars across return/assign/call/nested-closure boundaries)
- `Closures/NoParensInClosureParams.swift` — `{ (x, y) in }` → `{ x, y in }` when no parameter has a type annotation

Tests — `Tests/SwiftiomaticTests/Rules/`:
- `Redundant/RedundantNilCoalescingTests.swift` (5)
- `Redundant/RedundantOverrideTests.swift` (9)
- `Redundant/RedundantEnumeratedTests.swift` (6)
- `Redundant/RedundantSetterACLTests.swift` (8)
- `Redundant/RedundantEscapingTests.swift` (7)
- `NoParensInClosureParamsTests.swift` (8)

### Notes

- All 6 use `RewriteSyntaxRule` (per direction: "always prefer rewriter capability"), even where the issue table tagged some as `.lint`-only.
- `RedundantOverride`, `RedundantSetterACL`, `RedundantEscaping` ship with `defaultValue: rewrite=false, lint=warn` so the rewrite is opt-in (the transform is destructive enough that user review is appropriate).
- Reviewed existing rules for overlap before writing — no duplication. `RedundantAccessControl` covers internal/public/extension/fileprivate redundancies and does not handle the `(set)`-matches-getter case targeted by `RedundantSetterACL`.
- Build verified via xc-swift diagnostics; all 6 test suites verified individually.
