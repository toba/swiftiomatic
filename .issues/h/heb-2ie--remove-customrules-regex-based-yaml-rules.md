---
# heb-2ie
title: Remove CustomRules (regex-based YAML rules)
status: completed
type: task
priority: normal
created_at: 2026-02-28T16:58:43Z
updated_at: 2026-02-28T17:05:52Z
sync:
    github:
        issue_number: "16"
        synced_at: "2026-03-01T01:01:31Z"
---

Remove the CustomRules mechanism — regex-based lint rules defined in YAML config. This contradicts the AST-only philosophy and is already non-functional (skipped in RuleLoader).

## Files to remove
- [x] `Lint/Rules/CustomRules.swift` (169 lines)
- [x] `Configuration/RegexConfiguration.swift` (175 lines)  
- [x] `Models/CustomRuleTimer.swift` (35 lines)
- [x] `Tests/.../CustomRulesTests.swift` (1,175 lines)

## References to clean up
- [x] `Configuration/Configuration+RulesWrapper.swift` — custom rule merging/filtering
- [x] `Models/Linter.swift` — custom rule ID extraction
- [x] `Lint/Rules/CoreRules.swift` — registration
- [x] `RuleLoader.swift` — skip guard (becomes unnecessary)
- [x] `Configuration/Configuration+Parsing.swift` — YAML parsing for custom_rules
- [x] Any other references to CustomRules, CustomRulesConfiguration, RegexConfiguration, CustomRuleTimer

## Outcome
- Closes kmp-lex issue (15 disabled tests become deletions)
- ~1,500 lines removed
- Only AST-based rules remain


## Summary of Changes

Removed the entire CustomRules mechanism (regex-based YAML-defined lint rules). This contradicted the AST-only philosophy and was already non-functional (skipped in RuleLoader). Deleted 5 files, cleaned references in 10 more. Closes kmp-lex (15 disabled CustomRules tests are now gone). ConditionallySourceKitFree protocol left in place as harmless dead code in the rule protocol infrastructure.
