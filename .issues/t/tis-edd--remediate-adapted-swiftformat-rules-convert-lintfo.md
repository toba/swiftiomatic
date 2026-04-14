---
# tis-edd
title: 'Remediate adapted SwiftFormat rules: convert lint→format and add reference tests'
status: completed
type: epic
priority: high
created_at: 2026-04-14T16:06:07Z
updated_at: 2026-04-14T16:45:44Z
parent: 77g-8mh
sync:
    github:
        issue_number: "295"
        synced_at: "2026-04-14T18:45:51Z"
---

## Problem

Audit of the 45 adapted SwiftFormat rules (checked in child issues of #77g-8mh) found two categories of remediation needed:

1. **16 rules implemented as `SyntaxLintRule` instead of `SyntaxFormatRule`** — SwiftFormat auto-fixes all of these, so they should be format rules with rewriting capability
2. **38 rules missing nicklockwood/SwiftFormat reference tests** — only 7 of 45 adapted rules have `// MARK: - Adapted from SwiftFormat` test sections

## A. Rules needing lint → format conversion (16)

All from the redundancy category (nnl-svw). Currently `SyntaxLintRule` with `diagnose()`-only — no auto-fix.

| Rule | Swiftiomatic tests | SwiftFormat ref tests | Conversion complexity |
|---|---|---|---|
| `RedundantAsync` | 7 | 21 | Medium — strip `async` keyword |
| `RedundantBackticks` | 7 | 40 | Simple — strip backticks from identifiers |
| `RedundantBreak` | 6 | 4 | Medium — remove break statement |
| `RedundantClosure` | 8 | 52 | High — extract expression from IIFE |
| `RedundantEquatable` | 6 | 25 | High — remove hand-written `==` operator |
| `RedundantExtensionACL` | 6 | 2 | Simple — remove member access modifiers |
| `RedundantLet` | 7 | 17 | Simple — `let _ =` → `_ =` |
| `RedundantObjc` | 9 | 16 | Simple — remove `@objc` attribute |
| `RedundantProperty` | 8 | — | Medium — inline return value |
| `RedundantPublic` | 6 | 24 | Simple — remove `public` modifier |
| `RedundantSendable` | 7 | 8 | Simple — remove `Sendable` from inheritance |
| `RedundantStaticSelf` | 5 | 16 | Medium — `Self.x` → `x` |
| `RedundantThrows` | 7 | 17 | Simple — remove `throws` clause |
| `RedundantType` | 11 | 69 | Simple — remove type annotation |
| `RedundantTypedThrows` | 6 | 3 | Simple — simplify throws clause |
| `RedundantViewBuilder` | 7 | 37 | Simple — remove `@ViewBuilder` attribute |

**Already format rules (6):** RedundantInit, RedundantInternal, RedundantLetError, RedundantNilInit, RedundantOptionalBinding, RedundantRawValues — these still need SwiftFormat reference tests.

## B. Rules missing SwiftFormat reference tests (38)

Only 7 rules have adapted SwiftFormat tests: AndOperator, GenericExtensions, HoistAwait, HoistTry, IsEmpty, PreferKeyPath, SimplifyGenericConstraints.

### Redundancy (22 rules, 0 have SF ref tests)

| Rule | SM tests | SF tests available |
|---|---|---|
| RedundantAsync | 7 | 21 |
| RedundantBackticks | 7 | 40 |
| RedundantBreak | 6 | 4 |
| RedundantClosure | 8 | 52 |
| RedundantEquatable | 6 | 25 |
| RedundantExtensionACL | 6 | 2 |
| RedundantInit | 7 | 31 |
| RedundantInternal | 15 | 4 |
| RedundantLet | 7 | 17 |
| RedundantLetError | 7 | 2 |
| RedundantNilInit | 10 | 48 |
| RedundantObjc | 9 | 16 |
| RedundantOptionalBinding | 10 | 8 |
| RedundantProperty | 8 | — (no SF test file) |
| RedundantPublic | 6 | 24 |
| RedundantRawValues | 8 | 4 |
| RedundantSendable | 7 | 8 |
| RedundantStaticSelf | 5 | 16 |
| RedundantThrows | 7 | 17 |
| RedundantType | 11 | 69 |
| RedundantTypedThrows | 6 | 3 |
| RedundantViewBuilder | 7 | 37 |

### Modern Idioms (7 rules, 0 have SF ref tests)

| Rule | SM tests | SF tests available |
|---|---|---|
| Acronyms | 6 | 6 |
| AnyObjectProtocol | 6 | 6 |
| ApplicationMain | 4 | 3 |
| AssertionFailures | 8 | 8 |
| EnumNamespaces | 12 | 39 |
| PreferCountWhere | 8 | 5 |
| YodaConditions | 11 | 50 |

### Declaration/Cleanup (9 rules, 0 have SF ref tests)

| Rule | SM tests | SF tests available |
|---|---|---|
| EmptyBraces | 12 | 12 |
| EmptyExtensions | 9 | 6 |
| ExtensionAccessControl* | 20 | 28 |
| FileMacro | 6 | 3 |
| HoistPatternLet* | 14 | 48 |
| InitCoderUnavailable | 6 | 7 |
| ModifierOrder | 9 | 15 |
| ModifiersOnSameLine | 12 | 16 |
| NoExplicitOwnership | 9 | 3 |

*ExtensionAccessControl extends `NoAccessLevelOnExtensionDeclaration` (20 tests); HoistPatternLet extends `UseLetInEveryBoundCaseVariable` (13 tests) + `NoLabelsInCasePatterns` (1 test).

## Approach

1. Convert 16 lint rules to `SyntaxFormatRule` — change base class, convert `visit()` from `SyntaxVisitor` pattern to `SyntaxRewriter` pattern, return modified nodes
2. For each of the 38 rules missing SF reference tests, adapt tests from `~/Developer/swiftiomatic-ref/SwiftFormat/Tests/Rules/` into a `// MARK: - Adapted from SwiftFormat` section
3. Re-run `swift run generate-swiftiomatic` after conversions
4. Run full test suite to validate

## Priority order

Start with high-value conversions (simple complexity + many SF tests to adapt):
- RedundantType (69 SF tests), RedundantBackticks (40), RedundantViewBuilder (37), RedundantNilInit (48), YodaConditions (50), EnumNamespaces (39)
