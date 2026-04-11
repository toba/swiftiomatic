---
# zjh-4yu
title: Build assertLint/assertFormatting test infrastructure
status: completed
type: task
priority: normal
created_at: 2026-04-10T23:07:04Z
updated_at: 2026-04-10T23:13:53Z
parent: np8-60m
sync:
    github:
        issue_number: "168"
        synced_at: "2026-04-11T01:01:48Z"
---

Build test helpers adapted from Apple swift-format's `LintOrFormatRuleTestCase` pattern.

## Tasks
- [x] Create `MarkedText` type that extracts emoji markers (1️⃣, 2️⃣, etc.) and their UTF-8 offsets from source strings
- [x] Create `FindingSpec` struct with marker, message, and optional notes
- [x] Create `assertLint()` function for lint rules: parses marked source, runs rule, validates findings match specs
- [x] Create `assertFormatting()` function for format rules: validates both transformed output AND findings
- [x] Write tests for the test infrastructure itself
- [x] Verify with one existing rule (e.g., TrailingWhitespaceRule)

## Reference
- `.build/checkouts/swift-format/Sources/_SwiftFormatTestSupport/MarkedText.swift`
- `.build/checkouts/swift-format/Sources/_SwiftFormatTestSupport/FindingSpec.swift`
- `.build/checkouts/swift-format/Sources/_SwiftFormatTestSupport/DiagnosingTestCase.swift`
- `.build/checkouts/swift-format/Tests/SwiftFormatTests/Rules/LintOrFormatRuleTestCase.swift`
