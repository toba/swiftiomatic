---
# i29-ezi
title: 'Cat 5: Type Safety & Data Handling (6 rules)'
status: in-progress
type: feature
priority: normal
created_at: 2026-04-15T00:27:58Z
updated_at: 2026-04-25T22:56:06Z
parent: qlt-10c
sync:
    github:
        issue_number: "318"
        synced_at: "2026-04-25T22:56:10Z"
---

| SwiftLint Rule | Swiftiomatic Name | Scope | Description |
|---|---|---|---|
| `discouraged_optional_boolean` | NoOptionalBool | `.lint` | `Bool?` is confusing — prefer enum or non-optional with default |
| `discouraged_optional_collection` | NoOptionalCollection | `.lint` | `[T]?` should usually be `[T]` (empty = absent) |
| `non_optional_string_data_conversion` | PreferNonOptionalDataInit | `.lint` | Prefer `Data(_:)` over `String.data(using:)` (non-optional) |
| `optional_data_string_conversion` | PreferFailableStringInit | `.lint` | Prefer `String(bytes:encoding:)` for Data→String |
| `unowned_variable_capture` | PreferWeakCapture | `.lint` | Prefer `weak` over `unowned` — safer against crashes |
| `untyped_error_in_catch` | TypedCatchError | `.lint` | `catch error` without type cast loses type information |
