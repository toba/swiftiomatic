---
# 15z-71l
title: 'RequireCamelCaseIdentifiers: allow ''debug_'' and ''unsafe_'' prefixes'
status: completed
type: feature
priority: normal
created_at: 2026-05-02T02:50:41Z
updated_at: 2026-05-02T02:52:30Z
sync:
    github:
        issue_number: "623"
        synced_at: "2026-05-02T03:44:32Z"
---

## Goal

Update `RequireCamelCaseIdentifiers` to allow identifiers prefixed with `debug_` or `unsafe_`. The remainder of the name (everything after the prefix) must still satisfy the rule when enabled — i.e. lowerCamelCase, no further underscores, no leading uppercase.

## Examples (allowed)

- `debug_renderTree`
- `unsafe_pointerCast`

## Examples (still flagged)

- `debug_render_tree`     (underscore in remainder)
- `unsafe_PointerCast`    (uppercase first char of remainder)
- `debug_`                (empty remainder)
- `Debug_renderTree`      (prefix not lowercase — only literal `debug_`/`unsafe_` allowed)

## Plan

- [x] Add tests in `Tests/SwiftiomaticTests/Rules/RequireCamelCaseIdentifiersTests.swift` for accepted prefixes + still-flagged remainders
- [x] In `Sources/SwiftiomaticKit/Rules/Naming/RequireCamelCaseIdentifiers.swift`, in `diagnoseLowerCamelCaseViolations`, when the identifier text starts with `debug_` or `unsafe_`, validate the *remainder* against the same rules
- [x] Filtered tests pass; full suite green (3194 passed)

## Summary of Changes

- `Sources/SwiftiomaticKit/Rules/Naming/RequireCamelCaseIdentifiers.swift`: added `allowedUnderscorePrefixes = ["debug_", "unsafe_"]`. When the identifier text starts with one of these literal lowercase prefixes (and `allowUnderscores` is not already in effect), the prefix is stripped and the remainder is validated against the existing rules: non-empty, no further underscores, first char not `A...Z`. Empty remainders (`debug_`), uppercase remainder starts (`unsafe_PointerCast`), and underscored remainders (`debug_render_tree`) are still flagged. The prefix match is case-sensitive, so `Debug_renderTree` falls through to the normal check and is flagged on uppercase first char.
- `Tests/SwiftiomaticTests/Rules/RequireCamelCaseIdentifiersTests.swift`: added `allowsDebugAndUnsafePrefixes` and `debugAndUnsafePrefixRemaindersStillChecked`.
