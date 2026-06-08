---
# l6s-csh
title: 'Audit: don''t insert trailing commas in attribute argument lists'
status: completed
type: bug
priority: normal
created_at: 2026-06-08T19:41:54Z
updated_at: 2026-06-08T19:45:18Z
sync:
    github:
        issue_number: "724"
        synced_at: "2026-06-08T19:59:33Z"
---

Upstream swift-format fix (swiftlang/swift-format#1215, commit 68e501b9, 2026-06-08) stops inserting trailing commas into attribute argument lists.

Reference: ~/Developer/swiftiomatic-ref/swift-format/Sources/SwiftFormat/PrettyPrint/TokenStreamCreator.swift

Check Swiftiomatic's TokenStreamCreator / trailing-comma logic for the same bug and port the fix.

Test: write a case asserting attribute args like @available(*, deprecated, message: "x") never gain a trailing comma after the last argument.



## Summary of Changes

Ported swiftlang/swift-format#1215 (68e501b9) — added a parent-is-AttributeSyntax check in `visitLabeledExprList` so `markCommaDelimitedRegion` is skipped when the labeled-expr list is an attribute argument list with no existing trailing comma.

- Sources/SwiftiomaticKit/Layout/Tokens/TokenStream+Collections.swift: skip marking when parent is AttributeSyntax and no trailing comma.
- Tests/SwiftiomaticTests/Layout/CommaTests.swift: updated `alwaysTrailingCommasInAttribute` (renamed `alwaysTrailingCommasNotInsertedInAttribute`) to expect no inserted comma; added `alwaysTrailingCommasInMacroRoleAttribute` and `alwaysTrailingCommasKeepsExistingCommaInAttribute`.

Verified via filtered `CommaTests` run (38 passed).
