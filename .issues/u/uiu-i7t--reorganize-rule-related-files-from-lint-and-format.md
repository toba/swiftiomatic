---
# uiu-i7t
title: Reorganize rule-related files from Lint/ and Format/ into Rules/
status: completed
type: task
created_at: 2026-02-28T21:01:53Z
updated_at: 2026-02-28T21:01:53Z
---

Move scattered rule infrastructure files to their canonical homes:

## Moves

### Lint/ → Rules/
- [x] `Lint/Exports.swift` → `Rules/RuleRegistry+AllRules.swift` (rename + move)
- [x] `Lint/RulesFilter.swift` → `Rules/RulesFilter.swift`
- [x] `Lint/Rules/SuperfluousDisableCommandRule.swift` → `Rules/Documentation/SuperfluousDisableCommandRule.swift`
- [x] `Lint/Documentation/RuleDocumentation.swift` → `Rules/RuleDocumentation.swift`
- [x] `Lint/Documentation/RuleListDocumentation.swift` → `Rules/RuleListDocumentation.swift`

### Format/ → Support/ and Extensions/
- [x] `Format/EnumAssociable.swift` → `Support/EnumAssociable.swift`
- [x] `Format/Utilities.swift` → `Extensions/String+EditDistance.swift`
- [x] `Format/Singularize.swift` → `Extensions/String+Singularize.swift`

### Cleanup
- [x] Delete empty `Lint/Rules/` directory
- [x] Delete empty `Lint/Documentation/` directory

## Summary of Changes

Moved 8 files (5 from Lint/ to Rules/, 3 from Format/ to Support/ and Extensions/) with appropriate renames. Removed empty Lint/Rules/ and Lint/Documentation/ directories. Build passes clean. SIGSEGV in tests is pre-existing (tracked in wvf-6t1).
