---
# mp4-7xk
title: 'RedundantMainActorOnView: strip @MainActor from View/App/Scene types'
status: completed
type: feature
priority: normal
created_at: 2026-04-30T20:36:47Z
updated_at: 2026-04-30T20:43:20Z
parent: 7h4-72k
sync:
    github:
        issue_number: "570"
        synced_at: "2026-04-30T23:13:20Z"
---

Remove `@MainActor` attribute from struct/class/enum types that conform to SwiftUI's `View`, `App`, or `Scene`, since main-actor isolation is already implied.

## Decisions

- Group: `.redundancies`
- Default: `.warn` (default)
- Scope: any `struct`/`class`/`enum` whose inheritance clause names `View`, `App`, or `Scene` (unqualified).
- Implementation: `StaticFormatRule` with `transform` overloads on each decl type.

## Plan

- [x] Failing test
- [x] Implement `RedundantMainActorOnView`
- [x] Wire into `RewritePipeline.visit` for ClassDecl/StructDecl/EnumDecl
- [x] Verify test passes; regenerate schema



## Summary of Changes

- `Sources/SwiftiomaticKit/Rules/Redundancies/RedundantMainActorOnView.swift` — StaticFormatRule with overloads for `StructDeclSyntax`/`ClassDeclSyntax`/`EnumDeclSyntax`. Detects `View`/`App`/`Scene` conformance by unqualified inheritance name. Trivia of removed `@MainActor` is transferred to the next modifier or decl keyword.
- `Tests/SwiftiomaticTests/Rules/RedundantMainActorOnViewTests.swift` — 6/6 passing (View, App, Scene, non-View untouched, no-attribute untouched, mixed attributes).
- Wired into `RewritePipeline.visit(_: ClassDeclSyntax/EnumDeclSyntax/StructDeclSyntax)`.
- Schema regenerated; `redundantMainActorOnView` entry present.
