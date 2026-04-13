---
# c3o-wj6
title: Rule options UX in detail view
status: completed
type: feature
priority: normal
created_at: 2026-04-13T16:47:57Z
updated_at: 2026-04-13T17:20:35Z
sync:
    github:
        issue_number: "261"
        synced_at: "2026-04-13T18:05:11Z"
---

## Context

Rules can have configurable options exposed via `ConfigOptionDescriptor` (key, displayName, help, valueType, defaultValue, validValues). The `RuleDetailView` currently shows metadata (scope, opt-in, auto-fix) but has no UI for rule-specific options.

The infrastructure is already in place:
- `ConfigOptionDescriptor` describes each option with type info (`ConfigValueType`: bool, string, int, float, severity, list, enum)
- `RuleConfigurationEntry.configurationOptions` provides the array per rule
- Rules like `LineLengthRule` (thresholds + booleans), `NestingRule` (thresholds), `ImplicitlyUnwrappedOptionalRule` (enum picker), `FileNameRule` (strings, sets) already expose options

## Goal

Add a standard "Options" section to `RuleDetailView` that renders appropriate controls for each `ConfigOptionDescriptor`:

- [x] Map `ConfigValueType` to SwiftUI controls:
  - `bool` → `Toggle`
  - `int` / `float` → `Stepper` or `TextField` with formatter
  - `string` → `TextField`
  - `enum` → `Picker` (using `validValues`)
  - `severity` → `Picker` (warning / error)
  - `list` → tag-style editor or comma-separated `TextField`
- [x] Only show section when `entry.configurationOptions` is non-empty
- [x] Wire changes back to the document's per-rule configuration so they persist in `.swiftiomatic.yaml`
- [x] Show help text (from `ConfigOptionDescriptor.help`) as secondary label or tooltip
- [x] Show default value so users know what they're changing from


## Summary of Changes

Added an "Options" section to `RuleDetailView` that renders appropriate SwiftUI controls for each `ConfigOptionDescriptor`:

- **New file:** `Xcode/SwiftiomaticApp/Views/RuleOptionRow.swift` — `OptionBinding` enum + `RuleOptionRow` view mapping each `ConfigValueType` to the right control
- **Modified:** `Xcode/SwiftiomaticApp/Views/RuleDetailView.swift` — added Options section with binding helpers that read/write `document.configuration.lintRuleConfigs`

Values that match the default are automatically removed from the config dictionary, keeping the YAML clean.
