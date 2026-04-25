---
# 5v0-wjv
title: 'Cat 7: Metrics (10 rules)'
status: completed
type: feature
priority: normal
created_at: 2026-04-15T00:27:58Z
updated_at: 2026-04-25T23:33:15Z
parent: qlt-10c
sync:
    github:
        issue_number: "314"
        synced_at: "2026-04-25T23:53:21Z"
---

Entirely new territory — configurable threshold-based rules. All lint-only. Needs a two-tier severity model (warning threshold, error threshold) configurable via `.swiftiomatic.json`.

| SwiftLint Rule | Swiftiomatic Name | Scope | Description |
|---|---|---|---|
| `cyclomatic_complexity` | CyclomaticComplexity | `.lint` | Function cyclomatic complexity limit (default: 10 warn, 20 error) |
| `function_body_length` | FunctionBodyLength | `.lint` | Function body line count (default: 50 warn, 100 error) |
| `closure_body_length` | ClosureBodyLength | `.lint` | Closure body line count (default: 30 warn, 50 error) |
| `type_body_length` | TypeBodyLength | `.lint` | Type body line count (default: 250 warn, 350 error) |
| `file_length` | FileLength | `.lint` | File total line count (default: 400 warn, 1000 error) |
| `line_length` | LineLength | `.lint` | Characters per line (default: 120 warn, 200 error) |
| `function_parameter_count` | ParameterCount | `.lint` | Function parameter count (default: 5 warn, 8 error) |
| `large_tuple` | TupleSize | `.lint` | Tuple element count (default: 3 warn, 4 error) |
| `nesting` | NestingDepth | `.lint` | Max nesting depth (type: 1, function: 2) |
| `enum_case_associated_values_count` | AssociatedValueCount | `.lint` | Enum case associated value count (default: 5 warn, 6 error) |


## Summary of Changes

Implemented all 10 metrics rules with a two-tier (warning/error) threshold model.

### Foundational

- `Sources/ConfigurationKit/ConfigurationGroup.swift` — added `metrics` group.
- `Sources/SwiftiomaticKit/Syntax/SyntaxRule.swift` — added `diagnose(_:on:severity:)` overload that lets a rule emit at `.warn` or `.error` per finding (still gated by the rule's master `lint` setting). Refactored to share `emitFinding` with the existing single-severity overload.
- `Sources/GeneratorKit/RuleCollector.swift` — `schemaNodeFromType` now recognises `Int` and `Bool` properties on syntax-rule custom configs, reading the literal initializer for the default. Unblocks the threshold knobs in JSON Schema.
- `Tests/SwiftiomaticTests/Rules/LintOrFormatRuleTestCase.swift` — `assertLint` now takes an optional `configuration` so tests can inject custom thresholds.

### Rules (Sources/SwiftiomaticKit/Rules/Metrics/)

Each in the `metrics` group, lint-only, emits per-finding severity from `metricSeverity(value:warning:error:)`:

| Rule | Visits | Defaults |
|---|---|---|
| `CyclomaticComplexity` | functions, inits | warn 10 / err 20 (+ `ignoresCaseStatements`) |
| `FunctionBodyLength` | functions, inits, deinits, subscripts | 50 / 100 |
| `ClosureBodyLength` | closures | 30 / 50 |
| `TypeBodyLength` | classes, structs, enums, actors, protocols, extensions | 250 / 350 |
| `FileLength` | source file | 400 / 1000 (+ `ignoreCommentOnlyLines`) |
| `LineLengthLimit` | source file (renamed to avoid collision with the `lineLength` layout setting) | 120 / 200 |
| `ParameterCount` | functions, inits | 5 / 8 (+ `ignoresDefaultParameters`, default true) |
| `TupleSize` | tuple types | 3 / 4 |
| `NestingDepth` | types & funcs (separate stacks) | typeLevel 1, functionLevel 2 |
| `AssociatedValueCount` | enum cases | 5 / 6 |

`MetricsHelpers.swift` provides `metricSeverity` and `bodyLineCount`.

### Tests

10 test suites under `Tests/SwiftiomaticTests/Rules/Metrics/` covering pass-through, warn-threshold, error-threshold, and rule-specific options. All 22 metrics tests pass; full suite runs at 2897 passed / 0 failed.

### Verification done

- Build (debug, with tests) ✅
- Generator regenerated Pipelines+Generated.swift, ConfigurationRegistry+Generated.swift, ConfigurationSchema+Generated.swift, schema.json. Confirmed `metrics` group with all 10 rules in schema.json.
- Full test suite ✅ (incl. GeneratedFilesValidityTests).

### Note for reviewer

Rule named `LineLengthLimit` instead of `LineLength` because a layout setting already owns `LineLength` (pretty-printer wrap target). The semantic is the same as SwiftLint's `line_length` lint.
