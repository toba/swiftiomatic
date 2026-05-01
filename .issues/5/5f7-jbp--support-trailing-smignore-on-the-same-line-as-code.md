---
# 5f7-jbp
title: Support trailing //sm:ignore on the same line as code
status: completed
type: feature
priority: normal
created_at: 2026-05-01T00:28:45Z
updated_at: 2026-05-01T00:28:45Z
sync:
    github:
        issue_number: "595"
        synced_at: "2026-05-01T00:49:17Z"
---

Allow `sm:ignore` directives as trailing line comments on the same line as the
statement or member they apply to:

```swift
let x = "some code with trouble" // sm:ignore
var bar = foo+baz // sm:ignore: NoSemicolons
```

Previously only lone-line directives (on a line by themselves) were honored;
trailing comments were explicitly excluded (asserted by `RuleMaskTests.spuriousFlags`).

## Summary of Changes

- `Sources/SwiftiomaticKit/Syntax/RuleMask.swift`: extended `appendRuleStatus` to
  also scan the last token's trailing trivia of `CodeBlockItemSyntax` and
  `MemberBlockItemSyntax`. Added `trailingLineComments` helper that collects
  line comments before any newline (i.e., on the same line as the code).
  File-level (`SourceFileSyntax`) walk is unchanged — passes `nil` trailing token.
- `Tests/SwiftiomaticTests/Core/RuleMaskTests.swift`: dropped the
  `let b = 456 // sm:ignore: rule1` assertion from `spuriousFlags` (behavior
  intentionally changed); added `trailingIgnoreAllRules`,
  `trailingIgnoreSpecificRules`, and `trailingIgnoreOnMember` tests.
- `Documentation/IgnoringSource.md`: documented the trailing form.
- Doc comment on `RuleMask` updated with the new shape.

All 17 `RuleMaskTests` pass.
