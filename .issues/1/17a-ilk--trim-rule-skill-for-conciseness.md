---
# 17a-ilk
title: Trim /rule skill for conciseness
status: completed
type: task
priority: normal
created_at: 2026-04-12T21:59:57Z
updated_at: 2026-04-12T22:02:40Z
sync:
    github:
        issue_number: "237"
        synced_at: "2026-04-12T22:20:44Z"
---

- [x] Remove duplicated Scopes table (already in CLAUDE.md)
- [x] Extract swift-syntax API reference to references/swift-syntax-api.md
- [x] Remove Default Values Reference section
- [x] Trim Key Reference Files table
- [x] Condense Typed Violation Messages section
- [x] Merge SourceKit format caveat into Correctable section
- [x] Add when-to-use guidance to SourceKitASTRule and CollectingRule


## Summary of Changes

Reduced SKILL.md from 519 to 393 lines (24% reduction) by extracting swift-syntax API reference to a progressive-disclosure reference file, removing content duplicated from CLAUDE.md (Scopes table), removing Default Values Reference (readable from source), trimming Key Reference Files to non-obvious entries, condensing Typed Violation Messages, and adding when-to-use guidance for SourceKitASTRule and CollectingRule.
