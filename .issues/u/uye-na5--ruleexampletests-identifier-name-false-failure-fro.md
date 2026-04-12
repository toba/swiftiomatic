---
# uye-na5
title: 'RuleExampleTests: identifier_name false failure from prefixed_toplevel_constant'
status: completed
type: bug
priority: normal
created_at: 2026-04-12T19:34:44Z
updated_at: 2026-04-12T20:44:29Z
sync:
    github:
        issue_number: "230"
        synced_at: "2026-04-12T20:48:23Z"
---

## Problem

`RuleExampleTests/verifyExamples/identifier_name` fails with:

```
Expectation failed: (unexpectedViolations → [<nopath>:2:9: warning: Prefixed Top-Level Constant Violation: Top-level constants should be prefixed by `k` (prefixed_toplevel_constant)]).isEmpty → false
```

The `identifier_name` rule's non-triggering example `class Abc { static let MyLet = 0 }` (line 12 of `IdentifierNameRule+examples.swift`) triggers a violation from `prefixed_toplevel_constant` — a completely different rule.

## Analysis

The test harness in `LintTestHelpers.swift:622-637` calls `violations()` which runs through `Linter`. The config is built by `makeConfig()` at line 205 using `.onlyConfiguration(identifiers)` which should limit to only `identifier_name` + `redundant_disable_command`. Yet `prefixed_toplevel_constant` still fires.

`PrefixedTopLevelConstantRule` is `isOptIn = true`, so it shouldn't be enabled by default. Either:
1. The `Configuration` built by `makeConfig` doesn't properly exclude opt-in rules
2. The `Linter` pipeline ignores the configuration filter for certain rule types
3. Something in `applyingConfiguration(from: example)` at line 88 enables extra rules

## Key Files

- `Tests/SwiftiomaticTests/Support/LintTestHelpers.swift:205` — `makeConfig()`
- `Tests/SwiftiomaticTests/Support/LintTestHelpers.swift:83` — `violations()`
- `Tests/SwiftiomaticTests/Support/LintTestHelpers.swift:622` — `verifyExamples()`
- `Sources/SwiftiomaticKit/Rules/Naming/Identifiers/IdentifierNameRule+examples.swift:12` — offending example
- `Sources/SwiftiomaticKit/Rules/Naming/Identifiers/PrefixedTopLevelConstantRule.swift` — opt-in rule that shouldn't fire

## Reproduction

```
swift_package_test filter: "RuleExampleTests"
```

## Possible Fixes

- [ ] Fix `Configuration`/`Linter` to respect `.onlyConfiguration` filter and not run opt-in rules outside the set
- [ ] Or make the example less ambiguous (e.g. wrap in a struct so it's not top-level)

## Summary of Changes

Fixed 4 rule bugs exposed by the strict test assertions in a069d71:

1. **PrefixedTopLevelConstantRule**: added `AccessorBlockSyntax` skip so `let` bindings inside computed properties aren't flagged as top-level constants
2. **RedundantBackticksRule** (3 fixes from vjl-m9o rewrite): fixed `isInsideTypeDeclaration` to use `MemberBlockSyntax`, fixed `isInAccessorContext` to detect implicit getters via `AccessorBlockSyntax`, reordered `::`/`.` checks before `backtickAlwaysRequired`
3. **NoGroupingExtensionRule**: added `requiresPostProcessing` static property + generator support to route two-pass rules to the fallback path instead of the single-pass pipeline
4. **IdentifierNameRule**: removed incorrect `√` triggering example (math symbols are not case-violating)

Also discovered that Swift Testing misattributes failures from serialized parameterized tests — all failures were reported as `identifier_name` regardless of which rule actually failed.
