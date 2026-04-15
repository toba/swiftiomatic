---
# cgp-2xz
title: 'Cat 3: Modern Swift Idioms (11 rules)'
status: ready
type: feature
priority: normal
created_at: 2026-04-15T00:27:58Z
updated_at: 2026-04-15T00:27:58Z
parent: qlt-10c
sync:
    github:
        issue_number: "311"
        synced_at: "2026-04-15T00:34:45Z"
---

Prefer modern APIs and patterns.

| SwiftLint Rule | Swiftiomatic Name | Scope | Description |
|---|---|---|---|
| `force_cast` | NoForceCast | `.lint` | `as!` is dangerous (complements NoForceTry, NoForceUnwrap) |
| `toggle_bool` | PreferToggle | `.format` | `.toggle()` over `someBool = !someBool` |
| `unavailable_condition` | PreferUnavailable | `.format` | `#unavailable` over negated `#available` with empty body |
| `is_disjoint` | PreferIsDisjoint | `.lint` | `Set.isDisjoint(with:)` over `.intersection(_:).isEmpty` |
| `prefer_zero_over_explicit_init` | PreferDotZero | `.lint` | `.zero` over `CGPoint(x: 0, y: 0)` |
| `discouraged_none_name` | AvoidNoneName | `.lint` | `none` enum case / static member conflicts with Optional.none |
| `anonymous_argument_in_multiline_closure` | NamedClosureParams | `.lint` | `$0` in multiline closures harms readability |
| `fatal_error_message` | RequireFatalErrorMessage | `.lint` | `fatalError()` should have a descriptive message |
| `shorthand_operator` | PreferCompoundAssignment | `.format` | `x += 1` over `x = x + 1` |
| `prefer_self_type_over_type_of_self` | PreferSelfType | `.lint` | `Self` over `type(of: self)` |
| `void_function_in_ternary` | NoVoidTernary | `.lint` | Don't use ternary to call void functions |
