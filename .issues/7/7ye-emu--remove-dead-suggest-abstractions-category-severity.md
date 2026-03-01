---
# 7ye-emu
title: Remove dead Suggest/ abstractions (Category, Severity, Analysis)
status: completed
type: task
priority: normal
created_at: 2026-02-28T22:10:43Z
updated_at: 2026-02-28T23:07:18Z
sync:
    github:
        issue_number: "11"
        synced_at: "2026-03-01T01:01:30Z"
---

Remove vestigial suggest-engine abstractions that are never used:

- [x] Delete `Suggest/Analysis.swift` (empty file)
- [x] Delete `Suggest/Category.swift` (dead; RuleKind already categorizes)
- [x] Delete `Suggest/Severity.swift` (redundant with Confidence; filter was type-confused)
- [x] Edit `Suggest/Analyzer.swift` — remove categories/minSeverity, fix filter, dedupe SwiftSource creation
- [x] Edit `Suggest/Output/TextFormatter.swift` — group by Diagnostic.category + RuleKind.displayName
- [x] Add `displayName` to `Models/RuleKind.swift`
- [x] Edit `Rules/RuleCatalog.swift` — remove phantom Category entries
- [x] Edit `swiftiomatic.swift` — remove --category, --min-severity, --lint-only, --suggest-only; unify text output
- [x] Verify: swift build compiles cleanly
- [x] Verify: swift test passes


## Summary of Changes

Removed dead `Suggest/` abstractions (`Category`, `Severity`, `Analysis`):
- Deleted 3 vestigial files
- Simplified `Analyzer` (removed `categories`/`minSeverity` fields)
- Rewrote `TextFormatter` to group by `RuleKind.displayName` instead of `Category`
- Added `displayName` to `RuleKind`
- Removed phantom `Category` catalog entries from `RuleCatalog`
- Removed `--category`, `--min-severity`, `--lint-only`, `--suggest-only` CLI flags
- Unified text output path (no more engine-based splitting)
- Fixed several pre-existing build errors in Format/ and test files
