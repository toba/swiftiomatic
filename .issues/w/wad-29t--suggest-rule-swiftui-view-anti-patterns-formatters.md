---
# wad-29t
title: 'Suggest rule: SwiftUI view anti-patterns (formatters in body, unstable identity, etc.)'
status: completed
type: task
priority: normal
created_at: 2026-04-12T02:27:03Z
updated_at: 2026-04-12T21:52:11Z
parent: ogh-b3l
sync:
    github:
        issue_number: "208"
        synced_at: "2026-04-12T22:20:45Z"
---

## Overview

Create a suggest-scope rule detecting common SwiftUI performance and correctness anti-patterns in view bodies.

## Patterns to detect

- [ ] `GeometryReader` usage → suggest `Layout` protocol or `.visualEffect` modifier
- [ ] `NSOpenPanel` / `NSSavePanel` in SwiftUI view files → `.fileImporter` / `.fileExporter`
- [ ] `DateFormatter()` / `NumberFormatter()` / `MeasurementFormatter()` allocated inside `body` → cache as static/shared
- [ ] `.sorted(by:)` / `.filter { }` inside `ForEach` → precompute
- [x] `id: \.self` on non-Identifiable/mutable types, `UUID()` in ForEach → unstable identity
- [x] Top-level `if/else` in View body swapping root branches → stable root with conditional content
- [x] `withAnimation` inside `onChange` with frequent non-animated updates → `.animation(_:value:)` scoped modifier

## Notes

- All suggest scope — these require judgment to fix
- Could be one rule `SwiftUIViewAntiPatternsRule` or split by theme
- `GeometryReader` and `NSOpenPanel` are simple identifier checks
- Formatter-in-body needs to verify the allocation is inside a `body` computed property
- ForEach identity checks need to look at `ForEach` init arguments
