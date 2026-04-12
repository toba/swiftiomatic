---
# i74-cb6
title: 'Fix 5 test failures: StatementPositionRule no-SourceKit fallback + IdentifierNameRule emoji length'
status: completed
type: bug
priority: normal
created_at: 2026-04-12T01:37:36Z
updated_at: 2026-04-12T21:03:33Z
sync:
    github:
        issue_number: "205"
        synced_at: "2026-04-12T21:29:56Z"
---

## Problem

5 test failures:

### StatementPositionRule (4 failures)
- `noSpaceElseIfTriggers`, `extraSpaceElseTriggers`, `newlineCatchTriggers`, `newlineTabCatchTriggers`
- `defaultViolationRanges` filters matches by `syntaxKinds.starts(with: [.keyword])`
- Without SourceKit (in tests), syntax kinds are empty arrays → filter always returns false → no violations

### IdentifierNameRule (1 failure)
- `emojiIdentifierName` expects no violation for `let 👦🏼 = "👦🏼"`
- Emoji passes `containsOnlyAllowedCharacters` (non-ASCII OK) but fails length check (`"👦🏼".count == 1 < 3`)
- Should skip length check for entirely non-ASCII identifiers

## Tasks
- [x] Fix StatementPositionRule: add SourceKit availability fallback in `defaultViolationRanges`
- [x] Fix IdentifierNameRule: skip length + case checks for emoji identifiers
- [x] Fix DisableAllTests.enableAllFile: trailing_newline + blanket_disable_command extra violations
- [x] Fix UnifiedDiff.swift typed throws compilation error
- [x] Verify all 604 tests pass


## Status\n\nFixes were coded and tests pass locally, but changes were **never committed**. All 5 CI runs (v0.22.0 through v0.23.0) fail because of this.\n\n## Summary of Changes

**StatementPositionRule** (`Sources/SwiftiomaticKit/Rules/Whitespace/Braces/StatementPositionRule.swift`)
- Added SourceKit availability check in `defaultViolationRanges` — when SourceKit is unavailable (tests), falls back to `excludingSyntaxKinds` filtering instead of empty-kinds check that always returned false

**IdentifierNameRule** (`Sources/SwiftiomaticKit/Rules/Naming/Identifiers/IdentifierNameRule.swift`)
- Skip length check for identifiers consisting entirely of non-ASCII characters (emoji)
- Use `Character.isUppercase`/`isLowercase` in `isViolatingCase` instead of `String.isUppercase` — emoji have no case concept and should not trigger case violations

**DisableAllTests** (`Tests/.../DisableAllTests.swift`)
- Fix `enableAllFile`: add trailing newline (avoids `trailing_newline` violation) and filter infrastructure rules (`blanket_disable_command`, `redundant_disable_command`) from count

**CommandTests** (`Tests/.../CommandTests.swift`)
- Sort violation identifiers before comparison — violation order is non-deterministic between `blanket_disable_command` and `redundant_disable_command`

**UnifiedDiff.swift** (`Sources/SwiftiomaticKit/Support/UnifiedDiff.swift`)
- Change `throws(EncodingError)` to `throws` — `JSONEncoder.encode` uses untyped throws



## Confirmed Complete

All 5 fixes are in the committed codebase (verified 2026-04-12). The "never committed" note in the status section was stale — changes were included in subsequent commits. All 1864 tests pass.
