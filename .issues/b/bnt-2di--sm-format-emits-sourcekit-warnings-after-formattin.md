---
# bnt-2di
title: '`sm format` emits SourceKit warnings after formatting'
status: completed
type: bug
priority: normal
created_at: 2026-04-12T18:33:56Z
updated_at: 2026-04-12T18:52:35Z
sync:
    github:
        issue_number: "226"
        synced_at: "2026-04-12T19:05:19Z"
---

Running `sm format` on files produces SourceKit warnings to stderr after the format output. The format subcommand should not trigger SourceKit-dependent lint rules at all, but the output shows "lint corrections applied" lines followed by SourceKit context warnings.

Example:
```
Sources/Foo.swift: formatted
warning: SourceKit request made outside of rule execution context.
Sources/Foo.swift: lint corrections applied
```

- [x] Determine why format subcommand triggers SourceKit-dependent lint rules
- [x] Ensure format runs only format-scope rules (no SourceKit needed)
- [x] Verify `sm format` produces clean output without warnings


## Summary of Changes

**Root cause**: `FormatCommand.applyCorrectableLintRules()` loaded all correctable lint rules including SourceKit-dependent ones (e.g. `UnusedImportRule`, `ExplicitSelfRule`, `LiteralExpressionEndIndentationRule`). These rules attempted SourceKit requests without a `CurrentRule` context, triggering stderr warnings.

**Fixes**:
- `FormatCommand.swift`: Filter out `runsWithSourceKit` rules from both correctable and collecting rule sets; wrap `rule.correct()` in `CurrentRule.$identifier.withValue()` context
- `SwiftiomaticCLI.swift` (`runFix`): Wrap `rule.correct()` in `CurrentRule.$identifier.withValue()` context
- `CurrentRule.swift`: Widen access to `package` so CLI module can set rule context
- `RuleFilterTests.swift`: Added `formatCorrectableRulesExcludeSourceKit` (mock) and `realCorrectableRulesWithSourceKitExcludedFromFormat` (real rules) tests
