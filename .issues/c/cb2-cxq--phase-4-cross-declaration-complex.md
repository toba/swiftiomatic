---
# cb2-cxq
title: 'Phase 4: Cross-declaration / complex'
status: completed
type: task
priority: normal
created_at: 2026-04-14T18:36:52Z
updated_at: 2026-04-14T21:42:25Z
parent: c7r-77o
sync:
    github:
        issue_number: "300"
        synced_at: "2026-04-15T00:34:45Z"
---

- [x] `environmentEntry` — Use `@Entry` macro for EnvironmentValues. Requires recognizing `EnvironmentKey` struct + `EnvironmentValues` extension pattern spanning separate file-level declarations.
- [x] `opaqueGenericParameters` — Use `some Protocol` instead of `<T: Protocol>`. Coordinated modification of generic params, where clauses, and parameter types. Must track usage across entire declaration. 200+ lines in SwiftFormat reference.



## Summary of Changes

Implemented both cross-declaration/complex rules as format rules with auto-fix:

### `EnvironmentEntry` (15 tests)
- File-level two-phase rule: Phase 1 collects `EnvironmentKey` structs/enums, Phase 2 matches them to `EnvironmentValues` extension properties
- Replaces manual `EnvironmentKey` + getter/setter with `@Entry var name: Type = defaultValue`
- Removes the key type declaration after matching
- Handles: computed/stored/nil defaults, multi-line closure wrapping, access modifiers, enums, comments, let vs var, multiple keys/extensions

### `OpaqueGenericParameters` (26 tests)
- Visits `func`, `init`, `subscript` declarations with generic parameters
- Analyzes each generic type for eligibility: must appear exactly once in params, not in return type/body/attributes/effects/closures/variadic/other constraints
- Replaces eligible types with `some Protocol`, `some P1 & P2`, or concrete type (for `T == ConcreteType`)
- Rebuilds generic parameter clause and where clause, removing consumed entries
- Handles: bracket constraints, where clause constraints, partial removal, `.Type`/`?` wrapping, nested functions, protocol requirements

Both rules are opt-in (`isOptIn = true`).
