---
# i29-ezi
title: 'Cat 5: Type Safety & Data Handling (6 rules)'
status: completed
type: feature
priority: normal
created_at: 2026-04-15T00:27:58Z
updated_at: 2026-04-25T23:03:05Z
parent: qlt-10c
sync:
    github:
        issue_number: "318"
        synced_at: "2026-04-25T23:18:12Z"
---

| SwiftLint Rule | Swiftiomatic Name | Scope | Description |
|---|---|---|---|
| `discouraged_optional_boolean` | NoOptionalBool | `.lint` | `Bool?` is confusing — prefer enum or non-optional with default |
| `discouraged_optional_collection` | NoOptionalCollection | `.lint` | `[T]?` should usually be `[T]` (empty = absent) |
| `non_optional_string_data_conversion` | PreferNonOptionalDataInit | `.lint` | Prefer `Data(_:)` over `String.data(using:)` (non-optional) |
| `optional_data_string_conversion` | PreferFailableStringInit | `.lint` | Prefer `String(bytes:encoding:)` for Data→String |
| `unowned_variable_capture` | PreferWeakCapture | `.lint` | Prefer `weak` over `unowned` — safer against crashes |
| `untyped_error_in_catch` | TypedCatchError | `.lint` | `catch error` without type cast loses type information |



## Summary of Changes

Added six lint rules at `Sources/SwiftiomaticKit/Rules/` (root) plus matching test suites:

- `NoOptionalBool` — flags `Bool?` annotations, `Bool?` chain expressions, and `Optional<Bool>.some(true/false)`.
- `NoOptionalCollection` — flags `[T]?`, `[K:V]?`, `Array<T>?`, `Dictionary<K,V>?`, `Set<T>?`.
- `PreferNonOptionalDataInit` — flags `<expr>.data(using: .utf8)`; suggests `Data(<expr>.utf8)`.
- `PreferFailableStringInit` — flags `String(decoding:as: UTF8.self)` and `String.init(...)` form.
- `PreferWeakCapture` — flags `unowned` keyword in closure capture lists; ignores `unowned` stored properties.
- `TypedCatchError` — flags single-binding `catch let/var x` (and parenthesized form) without type cast or where clause.

All rules subclass `LintSyntaxRule<LintOnlyValue>`, are default-on (warning), and are root-level (no group). Generated files (`Pipelines+Generated.swift`, `ConfigurationRegistry+Generated.swift`, `schema.json`) regenerated.

Reference implementations under `~/Developer/swiftiomatic-ref/SwiftLint/Source/SwiftLintBuiltInRules/Rules/` were used as the basis. Build green; 24 new tests pass.
