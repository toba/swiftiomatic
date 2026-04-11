---
# nk3-b8j
title: Review upstream SwiftLint, SwiftFormat, and swift-format releases for porting opportunities
status: completed
type: task
priority: normal
created_at: 2026-04-11T17:37:51Z
updated_at: 2026-04-11T18:10:04Z
sync:
    github:
        issue_number: "185"
        synced_at: "2026-04-11T18:44:01Z"
---

Review the latest releases of the three cited linting/formatting tools for features, rules, and fixes worth porting to Swiftiomatic.

## nicklockwood/SwiftFormat — `0.60.1` (Mar 7, 2026)

- [x] Fixed `redundantSendable` removing `Sendable` conformance on types in public extensions — **we have `redundant_sendable` but it only checks `@MainActor` types, not public extension context; gap noted**
- [x] Fixed `redundantSendable` leaving extra space when removing `:` — N/A, our rule is lint-only (not correctable)
- [x] **`redundant_property` fixed** — now skips variables with explicit type annotations (`binding.typeAnnotation == nil` guard added); test added
- [x] Updated `enumNamespaces` to preserve Swift Testing suites as structs — **already handled**: our `enum_namespaces` skips all types with attributes (`guard attributes.isEmpty`), so `@Suite` structs are safe

## realm/SwiftLint — `0.63.2` (Jan 26, 2026)

### New rules to consider porting

- [x] `unneeded_throws_rethrows` — **already implemented** as `unneeded_throws_rethrows` rule
- [x] `unneeded_escaping` — **already implemented** with taint analysis for escape tracking
- [x] `multiline_call_arguments` — **already implemented** with `max_number_of_single_line_parameters` and `allows_single_line` options

### Notable changes

- [x] `redundant_self` — **already implemented** with `only_in_closures` (default true) and `keep_in_initializers` options
- [x] `vertical_whitespace_between_cases` — **already has** `separation` config (`always`/`never`)
- [x] `line_length` — **already correct**: `FunctionLineVisitor` collects from signature start to `signature.endPositionBeforeTrailingTrivia`, excluding bodies
- [x] `large_tuple` — **already has** `ignore_regex` option for `Regex<(...)>` generic arguments
- [x] `--disable-sourcekit` — N/A, our design is inverted: SourceKit is **opt-in** via `--sourcekit` flag (disabled by default)

## swiftlang/swift-format — `602.0.0` (Sep 16, 2025)

### Notable changes

- [ ] `dump-effective-configuration` subcommand — **we don't have this**; CLI has `analyze`, `format`, `list-rules`, `generate-docs`, `migrate` but no config introspection
- [x] `UseLetInEveryBoundCaseVariable` — **no equivalent rule**; low priority, niche pattern
- [ ] **File-level ignore directive** — our `sm:disable` supports `:previous`/`:this`/`:next` scopes only; bare `sm:disable RULE` disables until `sm:enable`; no explicit file-level scope like `sm:disable:file`
- [x] **Linter warnings by default** — **already matches**: our `SeverityOption` defaults to `.warning`
- [x] Severity in configuration — **we kept severity** (per-rule configurable); noted divergence from swift-format's removal
- [ ] `@_implementationOnly` import grouping — **our `SortImportsRule` treats all imports as one alphabetical group**; no attribute-based grouping
- [x] Comments in config files — **already supported**: YAML natively supports comments
- [x] `unsafe` expression support — **handled**: `Swift62ModernizationRule` detects unsafe buffer pointers and suggests `Span`/`RawSpan` migration
- [x] `InlineArray` type sugar — **handled**: `Swift62ModernizationRule` suggests `InlineArray<N, T>` for homogeneous tuples (SE-0453)
- [x] Unified whitespace handling — **already our design**: single rule set with `.lint`/`.format` scopes


## Summary

### Already implemented (16/22)
All SwiftLint 0.63.x rules and config options already exist. swift-format design choices (warnings default, unified whitespace, YAML comments) already match.

### Fixed (1/22)
- `redundant_property` now preserves variables with explicit type annotations

### Future work (5/22)
- `dump-effective-configuration` CLI subcommand
- File-level `sm:disable:file` scope
- `@_implementationOnly` import grouping in `SortImportsRule`
- `redundant_sendable` public extension context awareness
- `UseLetInEveryBoundCaseVariable` (low priority)
