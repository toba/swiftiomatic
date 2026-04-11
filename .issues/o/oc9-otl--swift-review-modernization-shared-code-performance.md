---
# oc9-otl
title: 'Swift review: modernization, shared code, performance'
status: completed
type: task
priority: normal
created_at: 2026-04-11T02:42:35Z
updated_at: 2026-04-11T02:42:35Z
sync:
    github:
        issue_number: "172"
        synced_at: "2026-04-11T02:45:17Z"
---

## Changes

- [x] Cache `CachedRegex.numberOfCaptureGroups` at init — avoids repeated `NSRegularExpression` allocation on every access
- [x] Replace `SwiftLintConfigParser.ruleConfigs` from `nonisolated(unsafe) var [String: Any]` to `var [String: ConfigValue]` — removes `nonisolated(unsafe)` and `Any`
- [x] Extract `DeclModifierListSyntax.accessibility` from fileprivate in MissingDocsRule to shared `SwiftSyntax+Declarations.swift`
- [x] Extract OptionsTab inline Binding allocations to computed properties — avoids per-render closure re-creation
- [x] Simplify `Array+Parallel.parallelMap` — replaced two `@unchecked Sendable` wrapper classes and `UnsafeMutableBufferPointer` manipulation with `Array(unsafeUninitializedCapacity:)` + `nonisolated(unsafe) let` bindings

## Summary of Changes

Five targeted improvements from swift review: one performance fix (cached regex capture groups), one type-safety fix (ConfigValue replacing Any), one shared code extraction (accessibility extension), one SwiftUI best practice (OptionsTab bindings), and one code simplification (parallel map). All 445 tests pass.
