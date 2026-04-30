---
# dx8-cmw
title: NoFormatterInSwiftUIBody
status: completed
type: feature
priority: normal
created_at: 2026-04-30T21:27:03Z
updated_at: 2026-04-30T21:31:56Z
parent: 7h4-72k
sync:
    github:
        issue_number: "586"
        synced_at: "2026-04-30T23:13:22Z"
---

Lint formatter initializers (`NumberFormatter`, `DateFormatter`, `MeasurementFormatter`) constructed inside a SwiftUI `body: some View` / `body: some Scene` accessor — re-allocated on every render.

## Decisions

- Group: `.idioms`
- Default: `.warn`
- Lint-only.
- Trigger: a `<Formatter>()` init expression whose ancestors include a computed property with name `body` and a `SomeOrAnyTypeSyntax` of `View`/`Scene` return type.

## Plan

- [x] Failing test
- [x] Implement `NoFormatterInSwiftUIBody`
- [x] Verify test passes; regenerate schema



## Summary of Changes

- LintSyntaxRule visiting `VariableDeclSyntax`, gated on `body: some View|Scene`. Walks the accessor with a `FormatterInitCollector`. Covers NumberFormatter, DateFormatter, MeasurementFormatter, ByteCountFormatter, DateComponentsFormatter, DateIntervalFormatter, ListFormatter, PersonNameComponentsFormatter.
- 6/6 tests passing.
- Schema regenerated.
