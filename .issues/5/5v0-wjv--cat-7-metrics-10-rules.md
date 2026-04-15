---
# 5v0-wjv
title: 'Cat 7: Metrics (10 rules)'
status: ready
type: feature
priority: normal
created_at: 2026-04-15T00:27:58Z
updated_at: 2026-04-15T00:27:58Z
parent: qlt-10c
sync:
    github:
        issue_number: "314"
        synced_at: "2026-04-15T00:34:45Z"
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
