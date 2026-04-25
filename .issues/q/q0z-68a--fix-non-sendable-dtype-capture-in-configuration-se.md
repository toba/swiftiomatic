---
# q0z-68a
title: Fix non-Sendable D.Type capture in Configuration setting/rule entries
status: completed
type: bug
priority: normal
created_at: 2026-04-25T17:12:34Z
updated_at: 2026-04-25T17:38:05Z
sync:
    github:
        issue_number: "404"
        synced_at: "2026-04-25T17:39:15Z"
---

## Problem

Swift 6 strict concurrency emits warnings in `Sources/SwiftiomaticKit/Configuration/Configuration.swift`:

> Capture of non-Sendable type 'D.Type' in an isolated closure

Two locations:

1. `entry(for:)` — `SettingEntry` decode/encode closures at ~lines 92-99
   - `config[D.self] = value` (decode closure)
   - `container.encode(config[D.self], forKey: codingKey)` (encode closure)

2. `ruleEntry(for:)` — `RuleEntry` decode/encode/disable/enable closures at ~lines 142-161
   - Same pattern with `R.Type` captured by `@Sendable` closures

## Root cause

The closures are typed as `@Sendable` (see `SettingDecoder` and `SettingEncoder` typealiases). They capture the generic type parameter `D.Type` / `R.Type` from the surrounding `open<D: LayoutRule>(_: D.Type)` / `open<R: SyntaxRule>(_: R.Type)` opener functions.

Under Swift 6 strict concurrency, a metatype `T.Type` is only Sendable if `T` is Sendable. Since `LayoutRule` and `SyntaxRule` don't require `Sendable` conformance on the conforming type (only their `Value` is Sendable), capturing `D.Type` in a `@Sendable` closure is unsafe.

## Tasks

- [x] Capture pre-fix warning state (visible in editor; full `swift_diagnostics` build is currently blocked by unrelated rule-folder reorganization breakage in `GeneratePaths.swift` / `GeneratePlugin/plugin.swift`, both of which still reference `Syntax/Rules` and `Layout/Rules` paths that no longer exist after commit 967d185d)
- [x] Determine the correct fix: Option A (`Sendable` requirement on the protocols) with `@unchecked Sendable` on the two `SyntaxRule` base classes (`LintSyntaxRule`, `RewriteSyntaxRule`), since their conformers are classes that inherit from non-Sendable swift-syntax types and store a non-Sendable `Context`. Only metatypes are captured in the closures — instances are never sent across isolation domains.
- [x] Applied fix across four files plus 132 subclass restate-conformance edits and one stale `nonisolated(unsafe)` cleanup. Verified clean: 0 errors, 0 warnings.
- [x] Verified no behavioral regression — full test suite passes (2576 tests, 0 failures).



## Summary of Changes

Four files modified, all minimal:

1. `Sources/SwiftiomaticKit/Layout/LayoutRule.swift:12` — `LayoutRule: Configurable` → `LayoutRule: Configurable, Sendable`. All concrete conformers are stateless structs and gain `Sendable` automatically.

2. `Sources/SwiftiomaticKit/Syntax/SyntaxRule.swift:5` — `SyntaxRule: Configurable where ...` → `SyntaxRule: Configurable, Sendable where ...`.

3. `Sources/SwiftiomaticKit/Syntax/Linter/LintSyntaxRule.swift:5` — added `, @unchecked Sendable` to the inheritance clause. Inherits from non-Sendable `SyntaxVisitor` and stores a non-Sendable `let context: Context`; `@unchecked` is correct because rule **instances** are never sent across isolation domains — the closures capture only the **metatype**, which becomes `Sendable` once the class itself is.

4. `Sources/SwiftiomaticKit/Syntax/Rewriter/RewriteSyntaxRule.swift:4` — same pattern as `LintSyntaxRule`.

No changes to `Configuration.swift` itself — the `@Sendable` decode/encode/disable/enable closures stop emitting capture warnings once `D.Type` / `R.Type` become Sendable metatypes.

## Verification status

Full build verification is blocked by a pre-existing breakage in commit `967d185d` (rule folder reorganization): `Plugins/GeneratePlugin/plugin.swift:24-25` and `Sources/GeneratorKit/GeneratePaths.swift:91-92` still reference `Layout/Rules` and `Syntax/Rules` directories that no longer exist (rules now live under `Sources/SwiftiomaticKit/Rules/<group>/`). `swift_diagnostics` aborts with `Could not list the directory .../Syntax/Rules` before reaching the SwiftiomaticKit module.

Per CLAUDE.md guidance, this out-of-scope breakage was not addressed in this issue. Status set to `review` for human verification once the Generator paths are fixed.



## Final Resolution

After the initial four-file fix, the wider build surfaced two additional issues that needed resolving for a clean build:

### 1. Pre-existing hard error in `Configuration.swift:267`

`package extension Configuration: Codable` is invalid — Swift forbids access modifiers on extensions that declare protocol conformances. Reverted to `extension Configuration: Codable` with explicit `package` modifiers on `init(from:)` and `encode(to:)`. (This was committed by another agent before this session.)

### 2. Restated `@unchecked Sendable` on 132 rule subclasses

When a class is `@unchecked Sendable`, Swift requires every concrete subclass to restate the conformance — otherwise the compiler emits a warning. After adding `@unchecked Sendable` to `LintSyntaxRule` and `RewriteSyntaxRule`, 132 concrete rule subclasses needed the restatement. Applied via a single regex script across `Sources/SwiftiomaticKit/Rules/**/*.swift`, adding `, @unchecked Sendable` before the opening brace of each `class X: LintSyntaxRule<...>` / `class X: RewriteSyntaxRule<...>` declaration.

### 3. Stale `nonisolated(unsafe)` in `SyntaxFindingCategory.swift`

The `private nonisolated(unsafe) let ruleType: any SyntaxRule.Type` workaround is no longer necessary now that `any SyntaxRule.Type` is `Sendable`. Removed the `nonisolated(unsafe)` qualifier — Swift now confirms it's redundant.

## Verification

- `xc-swift swift_diagnostics` (with tests): **0 errors, 0 warnings**.
- `xc-swift swift_package_test`: **2576 tests passed, 0 failed** in 10.3s. Performance suite ran with no regressions.

## Files modified (final tally)

- `Sources/SwiftiomaticKit/Layout/LayoutRule.swift` — protocol gains `Sendable`.
- `Sources/SwiftiomaticKit/Syntax/SyntaxRule.swift` — protocol gains `Sendable`.
- `Sources/SwiftiomaticKit/Syntax/Linter/LintSyntaxRule.swift` — base class gains `, @unchecked Sendable`.
- `Sources/SwiftiomaticKit/Syntax/Rewriter/RewriteSyntaxRule.swift` — base class gains `, @unchecked Sendable`.
- `Sources/SwiftiomaticKit/Configuration/Configuration.swift` — reverted invalid `package extension … Codable` to `extension … Codable` with per-member `package`.
- `Sources/SwiftiomaticKit/Findings/SyntaxFindingCategory.swift` — removed redundant `nonisolated(unsafe)`.
- `Sources/SwiftiomaticKit/Rules/**/*.swift` — 132 concrete rule subclasses each gain `, @unchecked Sendable`.
