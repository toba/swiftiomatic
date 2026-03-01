---
# c54-uak
title: Fix swift-review findings in SwiftiomaticTests
status: completed
type: task
priority: normal
created_at: 2026-03-01T06:24:47Z
updated_at: 2026-03-01T06:31:55Z
sync:
    github:
        issue_number: "119"
        synced_at: "2026-03-01T06:46:19Z"
---

Reduce test boilerplate via shared helpers:
- [x] Create SuggestTestHelpers.swift with suggestViolations() and expectFindings()
- [x] Simplify 9 suggest test files to use new helpers
- [x] Add ruleViolations() helper to LintTestHelpers.swift
- [x] Remove 6 private violations() wrappers in rule test files
- [x] Fix @unchecked Sendable on TestFileManager in LinterCacheTests.swift
