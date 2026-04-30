---
# gbr-jrd
title: 'PreferOfficialCDecl: @_cdecl → @c'
status: completed
type: feature
priority: normal
created_at: 2026-04-30T20:12:19Z
updated_at: 2026-04-30T20:20:57Z
parent: 7h4-72k
sync:
    github:
        issue_number: "571"
        synced_at: "2026-04-30T23:13:20Z"
---

Rewrite `@_cdecl` to `@c` (Swift 6.3 official spelling, SE-0407).

Trivially mechanical rewrite. Sibling-shape to `PreferMainAttribute`.

## Plan

- [x] Failing test (`Tests/SwiftiomaticTests/Rules/PreferOfficialCDeclTests.swift`)
- [x] Implement `PreferOfficialCDecl` as `StaticFormatRule<BasicRuleValue>` in `Sources/SwiftiomaticKit/Rules/Declarations/`
- [x] `group: .declarations`, default lint level `.warn` (default)
- [x] Verify test passes; build regenerates schema
- [x] Confirm rule appears in `schema.json`

## Acceptance

- `@_cdecl("foo") func bar()` becomes `@c("foo") func bar()`
- Argument list (the symbol name) is preserved verbatim
- Existing `@c` is untouched
- Other attributes are untouched



## Summary of Changes

- Added `Sources/SwiftiomaticKit/Rules/Declarations/PreferOfficialCDecl.swift` (StaticFormatRule, group `.declarations`, default `.warn`).
- Added `Tests/SwiftiomaticTests/Rules/PreferOfficialCDeclTests.swift` — 3 tests passing.
- Wired into `RewritePipeline.visit(_: AttributeSyntax)` alongside `PreferMainAttribute`.
- `schema.json` regenerated; `preferOfficialCDecl` entry present.
