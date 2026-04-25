---
# anc-31a
title: Fix camelCase key derivation in LintSyntaxRule/RewriteSyntaxRule overrides
status: completed
type: bug
priority: high
created_at: 2026-04-25T18:51:46Z
updated_at: 2026-04-25T18:51:46Z
sync:
    github:
        issue_number: "407"
        synced_at: "2026-04-25T18:52:10Z"
---

The camelCase key derivation fix in `Configurable.key` was shadowed by `class var key` overrides in `LintSyntaxRule` and `RewriteSyntaxRule` base classes that still used the old 'lowercase first character only' logic. This caused acronym-prefixed rules like `URLMacro` to produce `uRLMacro` instead of `urlMacro` at the registry level, even though the unit test for `configurationKey(forTypeName:)` passed.

The overrides were added with a comment about vtable dispatch through protocol existentials but reverted to the buggy implementation. Both now delegate to `configurationKey(forTypeName:)`.

## Summary of Changes

- `Sources/SwiftiomaticKit/Syntax/Linter/LintSyntaxRule.swift` — `class var key` now calls `configurationKey(forTypeName:)`
- `Sources/SwiftiomaticKit/Syntax/Rewriter/RewriteSyntaxRule.swift` — same fix
- Both files now import `ConfigurationKit`
