---
# 1yw-nak
title: Format command ignores correctable Swiftiomatic rules
status: completed
type: bug
priority: normal
created_at: 2026-04-13T19:10:02Z
updated_at: 2026-04-13T19:10:02Z
sync:
    github:
        issue_number: "262"
        synced_at: "2026-04-13T19:10:12Z"
---

## Context

`Swiftiomatic.format()` in `PublicAPI.swift` only ran swift-format's pretty-printer. Correctable rules from the Swiftiomatic rule registry (both lint-scope and format-scope) were never applied during formatting — affecting both the Xcode extension and the CLI's public API.

The CLI (`sm format`) had a separate second pass via `applyCorrectableLintRules()` but the public API consumers (extension, tests) did not.

## Fix

Enhanced `Swiftiomatic.format()` to run a second pass after swift-format: loads all correctable, non-SourceKit rules via `RuleResolver.loadRules()` and applies corrections in memory.

Also changed `switch_case_alignment` from lint to format scope with auto-fix.

- [x] Add correctable rule pass to `Swiftiomatic.format()`
- [x] Make `switch_case_alignment` a format-scope correctable rule
- [x] Rename severity option display to "Lint as"

## Summary of Changes

Added correctable rule pass to `PublicAPI.swift` format method; made `switch_case_alignment` a correctable format rule with rewriter.
