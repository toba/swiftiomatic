---
# c12-swt
title: 'Self-lint review: dogfood Swiftiomatic on Sources/ (293 warnings)'
status: ready
type: task
priority: normal
created_at: 2026-04-30T23:21:23Z
updated_at: 2026-04-30T23:21:23Z
sync:
    github:
        issue_number: "589"
        synced_at: "2026-04-30T23:23:58Z"
---

Full Swift code review of `Sources/` (5 modules, 372 files) using the `/swift` skill checklist.

## Headline

The biggest finding is that **Swiftiomatic does not dogfood its own rules**. `sm lint -r -p Sources/` produces **293 warnings** on the project's own source. Many of these are auto-fixable by `sm format`. Excluding `Generated/`, the codebase is otherwise modern and clean — no XCTest holdovers, no GCD/callback concurrency, no `Any` leakage, no obvious duplication.

## 1. Dogfood — fix the 293 self-lint warnings

Top offenders by count (`sm lint -r -p Sources/`):

| Count | Rule | Auto-fix |
|---|---|---|
| 44 | wrapTernary | yes (format) |
| 24 | redundantType | yes |
| 24 | preferTrailingClosures | yes |
| 23 | typeBodyLength | no (refactor) |
| 22 | useImplicitInit | yes |
| 20 | redundantSelf | yes |
| 15 | preferCommaConditions | yes |
| 9  | fileLength | no (refactor) |
| 7  | uppercaseAcronyms | yes |
| 6  | redundantOptionalBinding | yes |
| 6  | preferStaticOverClassFunc | yes |
| 4  | preferFinalClasses | yes |
| 4  | noParensInClosureParams | yes |
| 4  | noForceCast | manual |
| 4  | functionBodyLength | no (refactor) |
| 3  | unusedSetterValue | manual |
| 3  | preferContains | yes |
| 3  | nestingDepth | no (refactor) |
| 2  | redundantProperty | yes |
| 2  | redundantClosure | yes |
| 2  | patternBinding | yes |
| 2  | noRetroactiveConformances | manual |
| 2  | noLocalDocComments | yes |
| 2  | noLeadingUnderscores | manual |
| 2  | closureBodyLength | no (refactor) |
| 1  | tupleSize, preferReduceInto, preferFirstWhere, preferCompoundAssignment, orphanedDocComment, onlyOneTrailingClosureArgument, modifierOrder, camelCaseIdentifiers | mixed |

### High-signal individual findings

- `Sources/SwiftiomaticKit/Syntax/Linter/LintPipeline.swift:72` — `[noForceCast]` `as! R`
- `Sources/SwiftiomaticKit/Syntax/DocumentationComment.swift:159,188,232` — `[noForceCast]` `as! UnorderedList` (3x)
- `Sources/Swiftiomatic/Subcommands/LintFormatOptions.swift:177-178` — `[noRetroactiveConformances]`
- `Sources/SwiftiomaticKit/Syntax/Rewriter/StructuralFormatRule.swift:23,26,28` and `Linter/LintSyntaxRule.swift:13,16,17` — `[preferStaticOverClassFunc]` (final classes using `class func`/`class var`)
- `Sources/SwiftiomaticKit/Rules/Comments/RequireDocCommentSummary.swift:30-31` — `_forcesFallbackStorage`, `_forcesFallbackModeForTesting` violate `noLeadingUnderscores`
- `Sources/SwiftiomaticKit/Rules/Idioms/WarnSwapThenRemoveAll.swift:47` — `inout_` violates `camelCaseIdentifiers`
- `Sources/GeneratorKit/SyntaxVisitorOverrideCollector.swift:13` — `onlyOneTrailingClosureArgument`

### Files exceeding length limits

The `typeBodyLength` (23) and `fileLength` (9) hits cluster in:
- `Sources/SwiftiomaticKit/Layout/LayoutCoordinator.swift` (557 lines, type body 530, function body 277)
- `Sources/SwiftiomaticKit/Layout/Tokens/TokenStream+Appending.swift` (556 lines, type body 551)
- `Sources/SwiftiomaticKit/Configuration/Configuration+UpdateText.swift` (type body 365)
- `Sources/SwiftiomaticKit/Rules/Generics/OpaqueGenericParameters.swift` (type body 425)
- `Sources/SwiftiomaticKit/Rules/Redundancies/RedundantAccessControl.swift` (type body 426)
- `Sources/SwiftiomaticKit/Rules/Redundancies/UnusedArguments.swift` (type body 420)
- `Sources/SwiftiomaticKit/Rules/Redundancies/RedundantSelf.swift`, `RedundantReturn.swift`, `UseImplicitInit.swift`

These can be split into extension files (we already use that pattern for `TokenStream+*`).

## 2. Semantic findings (verified)

### 2a. `Configuration+UpdateText.swift:4` — `[orphanedDocComment]`

A `///` doc-comment is detached from its declaration. Either move it or convert to `//`.

## 3. What was checked and found clean

- **Any/AnyObject elimination** — only intentional bridging in `JSONValueEncoder` (CodingUserInfoKey requirement); `JSONValue` deliberately avoids `Any`.
- **Typed throws** — no `Result<T, E>` return types that should be typed throws; existing `throws(Type)` usage is correct.
- **Structured concurrency** — no `@escaping (Result...)` callbacks, no `DispatchQueue`/`DispatchGroup`/`NSLock`/`os_unfair_lock`. Synchronization uses `Mutex<T>` correctly throughout (`LintCache`, `ConfigurationLoader`, `DiagnosticsEngine`, `StderrDiagnosticPrinter`).
- **`@unchecked Sendable`** — every occurrence is on a `StaticFormatRule`/`LintSyntaxRule` subclass (inheriting from `SyntaxVisitor`/`SyntaxRewriter`, which are not `Sendable`). Investigated and scrapped in y5o-v8q (neither SE-0470 metatype case nor "all fields Sendable" case is structurally detectable).
- **`nonisolated(unsafe) let`** — only used for cached `Regex` literals (`Configurable.swift:8`, `RuleMask.swift`). `Regex` is not `Sendable` in 6.3, so these are correct.
- **Modernization** — no `@_cdecl`, `@_specialize`, `withObservationTracking`, `weak var`, `Notification.Name + userInfo`. (The codebase contains rules that lint these patterns, but the framework itself doesn't use them.)
- **AsyncStream cleanup** — no `AsyncStream` continuations in the framework (the rule `AsyncStreamMissingTermination` exists for user code).
- **Performance** — no `Data.dropFirst()` loops, no quadratic copy patterns, no `firstIndex(of:)` inside `for-in`. `.flatMap` usages reviewed — all are short, single-stage, on small node lists (no allocation hotspots). Lazy where appropriate (`NoFallThroughOnlyCases.swift:152`, `AsyncStreamMissingTermination.swift:22`, etc.).
- **Naming** — protocols (`Configurable`, `SyntaxRuleValue`, `LayoutRule`, `FindingCategorizing`) follow `-able`/`-ing` distinction correctly. Booleans read as assertions.
- **XCTest** — no `import XCTest` in framework sources.
- **Sequence vs Collection** — checked `LazySplitSequence` and `SortImports`; both correctly chosen.

## Recommended follow-up

Run `sm format -r -p -i Sources/` to auto-fix the bulk (~150+ warnings), then handle the structural ones (length, force casts, retroactive conformances, leading underscores) by hand. Most of the remaining manual work is splitting 5–6 large rule files into extension files following the existing `TokenStream+*` pattern.

## Plan

- [ ] Run `sm format -r -p -i Sources/` and review the diff
- [ ] Fix `[noForceCast]` in `LintPipeline.swift:72` and `DocumentationComment.swift:159,188,232`
- [ ] Fix `[noRetroactiveConformances]` in `LintFormatOptions.swift:177-178`
- [ ] Convert `class func`/`class var` to `static` in `StructuralFormatRule.swift` and `LintSyntaxRule.swift`
- [ ] Rename `_forcesFallbackStorage`, `_forcesFallbackModeForTesting`, `inout_`
- [ ] Split files exceeding `fileLength` (LayoutCoordinator, TokenStream+Appending, OpaqueGenericParameters, RedundantAccessControl, UnusedArguments, RedundantSelf, RedundantReturn, UseImplicitInit, Configuration+UpdateText)
- [ ] Fix `[orphanedDocComment]` in `Configuration+UpdateText.swift:4`
- [ ] Re-run `sm lint -r -p Sources/` until clean
