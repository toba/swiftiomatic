---
# tf1-32l
title: Fix all 87 build warnings
status: completed
type: bug
priority: normal
created_at: 2026-03-01T06:59:40Z
updated_at: 2026-03-01T07:06:33Z
sync:
    github:
        issue_number: "121"
        synced_at: "2026-03-01T08:00:21Z"
---

87 compiler warnings found via clean build diagnostics.

## Categories

- [x] ~80× `no calls to throwing functions occur within 'try' expression` in `+Configuration.swift` files
- [x] 2× `cast from 'SourceKitValue?' to unrelated type 'String' always fails` (CaptureVariableRule.swift, UnusedImportRule.swift)
- [x] 1× `default will never be executed` (ConditionalAssignmentRule.swift)
- [x] 1× `'init(validatingUTF8:)' is deprecated` (DynamicLibrary.swift)
- [x] 1× `trailing closure confusable with body` (Formatter+FormattingHelpers.swift)
- [x] 1× `initialization of variable 'cumulativeOptions' was never used` (Formatter.swift)
