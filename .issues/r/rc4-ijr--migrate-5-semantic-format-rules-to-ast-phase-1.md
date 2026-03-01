---
# rc4-ijr
title: Migrate 5 semantic format rules to AST (Phase 1)
status: completed
type: task
priority: normal
created_at: 2026-03-01T01:57:53Z
updated_at: 2026-03-01T02:06:09Z
sync:
    github:
        issue_number: "110"
        synced_at: "2026-03-01T03:57:24Z"
---

Migrate token-based FormatRule instances to SwiftSyntaxCorrectableRule equivalents.

## Steps
- [x] Delete accidentally created RedundantGetRule.swift
- [x] Upgrade ImplicitGetterRule to SwiftSyntaxCorrectableRule
- [x] Remove 5 token-based FormatRule files
- [x] Remove from format rule registry
- [x] Remove token-based test files
- [x] Fix cross-references in remaining tests (+ BlankLineAfterSwitchCase orderAfter)
- [x] Build and run tests

## Summary of Changes

Migrated 5 token-based FormatRule instances to their AST equivalents:
- **redundantBreak** → UnneededBreakInSwitchRule (removed token version)
- **redundantGet** → ImplicitGetterRule (upgraded to SwiftSyntaxCorrectableRule with Rewriter)
- **redundantLet** → RedundantDiscardableLetRule (removed token version)
- **redundantNilInit** → ImplicitOptionalInitializationRule (removed token version)
- **redundantLetError** → UntypedErrorInCatchRule (removed token version)

Deleted 11 files (5 rule sources, 1 accidental file, 5 test files), updated 5 files.
All AST rule tests pass. No new test failures introduced.
