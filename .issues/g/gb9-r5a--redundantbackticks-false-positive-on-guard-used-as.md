---
# gb9-r5a
title: 'RedundantBackticks: false positive on ''guard'' used as property name'
status: completed
type: bug
priority: normal
created_at: 2026-04-27T21:04:44Z
updated_at: 2026-04-27T21:19:11Z
sync:
    github:
        issue_number: "469"
        synced_at: "2026-04-28T02:39:59Z"
---

## Repro

```swift
guard isValidElseBlock(`guard`.body) else { return nil }
```

The backticks around `guard` are required here — `guard` is a Swift keyword being used as a property/identifier name. Removing the backticks produces a syntax error.

## Expected

RedundantBackticks should not flag identifiers whose unbacktick'd form is a reserved keyword that cannot be used as an identifier in this position.

## Actual

The rule reports the backticks as redundant.

## Notes

- File: `Sources/SwiftiomaticKit/Rules/Redundancies/RedundantBackticks.swift`
- Need to check whether the identifier text is a contextual vs. reserved keyword, and whether the position permits the unbacktick'd form.



## Summary of Changes

**Root cause:** `isAfterDot(_:)` in `Sources/SwiftiomaticKit/Rules/Redundancies/RedundantBackticks.swift` did not distinguish between the `base` and `declName` of a `MemberAccessExprSyntax`. When a backticked keyword like ```guard``` appeared as the **base** of a member access (```guard`.body`), the grandparent check passed and the rule treated it as if it were after the dot — falling through to the `specialAfterDot` allowlist (only `init`/`self`/`Type`) and stripping the backticks.

**Fix:** Tightened the member-access branch to require `memberAccess.declName.id == declRef.id`, and split out the `KeyPathPropertyComponentSyntax` branch (which has no `base`) into its own check.

**Tests added** in `Tests/SwiftiomaticTests/Rules/Redundant/RedundantBackticksTests.swift`:
- `keepBackticksOnKeywordAsMemberAccessBase` — the issue repro
- `keepBackticksOnKeywordAsBareExpression` — `let x = ``guard``` sanity case

All 40 `RedundantBackticksTests` pass.
