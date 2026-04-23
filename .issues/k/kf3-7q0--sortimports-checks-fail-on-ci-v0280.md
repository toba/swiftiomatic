---
# kf3-7q0
title: SortImports checks fail on CI (v0.28.0)
status: completed
type: bug
priority: high
created_at: 2026-04-23T16:39:35Z
updated_at: 2026-04-23T16:46:01Z
sync:
    github:
        issue_number: "361"
        synced_at: "2026-04-23T20:40:02Z"
---

## Problem

The v0.28.0 release workflow fails in CI because two SortImports checks produce unexpected output:

- disableSortImports() — fails at SortImportsTests.swift:335
- disableOrderedImportsMovingComments() — fails at SortImportsTests.swift:370

Both exercise // sm:ignore directive handling within import blocks. The formatted output does not match the expected string (LintOrFormatRuleTestCase.swift:149: assertStringsEqualWithDiff).

## Context

- CI run: Release workflow run 24846042723 on branch v0.28.0
- Commit: d365d12b (add RedundantFinal, PreferStaticOverClassFunc rules; extend RedundantReturn)
- Runner: macOS 26.3, Xcode 26.4
- Last passing release: v0.26.22

### Historical note

v0.27.0 and v0.27.1 had ~1860 failures across all suites (systemic regression from ConfigurationKit/JSONValue rewrite). Those were fixed by v0.28.0 — only the SortImports issue remains.

## TODO

- [x] Run failing checks locally to see the actual vs expected diff
- [x] Determine if // sm:ignore handling in SortImports was broken by the RedundantFinal/RedundantReturn commit or an earlier one
- [x] Fix the SortImports rule or update expectations
- [x] Confirm all checks pass locally
- [ ] Re-tag v0.28.0 (deferred — commit not yet pushed)


## Summary of Changes

**Root cause**: `// sm:ignore: SortImports` directives were not being honored because `RuleMask` normalized the type name to `sortImports` but the rule's actual key is `imports` (custom override). The `ruleState()` lookup used the actual key, so the directive was never found.

This affects ALL rules with custom keys (38 rules), not just SortImports.

**Fix**:
- Added `ConfigurationRegistry.typeNameToKey` reverse lookup mapping type-name-derived keys to actual configuration keys
- Updated `RuleMask.ruleStatusDirectiveMatch` to resolve custom keys through this mapping

**Also**: Restored `.githooks/pre-commit` hook (deleted in 7c690ae3) and configured `core.hooksPath` so tests run before commits.
