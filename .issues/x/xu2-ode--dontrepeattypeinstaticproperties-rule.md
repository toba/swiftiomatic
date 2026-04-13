---
# xu2-ode
title: DontRepeatTypeInStaticProperties rule
status: completed
type: task
priority: normal
created_at: 2026-04-12T23:57:19Z
updated_at: 2026-04-13T00:19:38Z
parent: shb-etk
sync:
    github:
        issue_number: "241"
        synced_at: "2026-04-13T00:25:21Z"
---

Static properties returning their enclosing type shouldn't include the type name in the property name.

**swift-format reference**: `DontRepeatTypeInStaticProperties.swift` in `~/Developer/swiftiomatic-ref/`

Triggers:
```swift
struct Color {
    static let blueColor = Color(...)    // ← "Color" repeated
    static let defaultColor = Color(...) // ← "Color" repeated
}
```

Preferred:
```swift
struct Color {
    static let blue = Color(...)
    static let `default` = Color(...)
}
```

`naming_heuristics` covers factory method prefixes and Bool naming but not this pattern.

## Checklist

- [x] Decide scope: lint (warning, not correctable)
- [x] Read reference implementation in swift-format
- [x] Create rule file with id `dont_repeat_type_in_static_properties`
- [x] Detect static properties whose name contains the enclosing type name (case-insensitive suffix match)
- [x] Only flag when the return type matches the enclosing type (or is inferred from initializer)
- [x] N/A — lint-only, no auto-rename
- [x] Requires suffix to be longer than bare type name (avoids false positives)
- [x] Add non-triggering and triggering examples
- [x] Run `swift run GeneratePipeline`
- [x] Verify examples pass via RuleExampleTests


## Summary of Changes

Created `DontRepeatTypeInStaticPropertiesRule` (lint, not correctable) at `Rules/Naming/Identifiers/`. Strips ObjC namespace prefixes before matching. Handles type annotations, initializer inference, Self, and explicit .init() calls.
