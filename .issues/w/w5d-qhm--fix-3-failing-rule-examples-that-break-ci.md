---
# w5d-qhm
title: Fix 3 failing rule examples that break CI
status: scrapped
type: bug
priority: normal
created_at: 2026-04-13T00:41:02Z
updated_at: 2026-04-13T00:50:14Z
sync:
    github:
        issue_number: "256"
        synced_at: "2026-04-13T00:55:41Z"
---

18 consecutive CI failures since v0.18.4. After the Xcode version fix in v0.21.1, the remaining failures are from:

1. **empty_braces linebreak style**: `hasLinebreakWithIndentation` and `targetTrivia` put the newline in leftBrace.trailingTrivia, but SwiftSyntax puts it in rightBrace.leadingTrivia. Result: non-triggering examples trigger, and corrections produce a blank line (`{\n\n}` instead of `{\n}`)
2. **fully_indirect_enum**: Rewriter transfers `indirect`'s leading trivia to the first remaining modifier even when `indirect` isn't the first modifier, overwriting the original indentation. Result: `{internal case` instead of `{\n    internal case`
3. **no_labels_in_case_patterns**: Non-triggering example `case .pair(first: let x, second: let second)` has matching label/variable `second`, which IS a violation

- [ ] Fix empty_braces linebreak trivia
- [ ] Fix fully_indirect_enum trivia transfer
- [ ] Fix no_labels_in_case_patterns example
- [ ] Verify tests pass locally



## Reasons for Scrapping

Superseded by a more comprehensive issue that captures the systemic pattern, not just the current 3 rule bugs.
