---
# i37-42u
title: Document trailing 'sm:ignore' placement requirement on multi-line statements
status: completed
type: bug
priority: normal
created_at: 2026-05-01T21:14:30Z
updated_at: 2026-05-01T21:23:21Z
sync:
    github:
        issue_number: "610"
        synced_at: "2026-05-01T21:40:15Z"
---

When a rule diagnoses on a multi-line node like `IfStmt`, a trailing `// sm:ignore` directive only attaches if it follows the **last token** of the node (the closing brace), not the first line.

## Repro

```swift
// Does NOT suppress useOrderedSetForUniqueAppend:
if !sourceFiles.contains(path) { // sm:ignore useOrderedSetForUniqueAppend
    sourceFiles.append(path)
}

// Does NOT suppress either:
if !sourceFiles.contains(path) {
    sourceFiles.append(path) // sm:ignore useOrderedSetForUniqueAppend
}

// DOES suppress (trailing on closing brace):
if !sourceFiles.contains(path) {
    sourceFiles.append(path)
} // sm:ignore useOrderedSetForUniqueAppend
```

## Why

`RuleStatusCollectionVisitor.applyDirectives` reads trailing trivia from the **last token** of each `CodeBlockItemSyntax`. The first-line trailing is on the `{` token (which is part of the if's body, not its last token). The trailing on the inner `.append` line attaches to the inner code-block-item, whose range doesn't cover the diagnosed IfStmt position.

This is correct per the implementation but is a sharp edge for users — every example in `Documentation/IgnoringSource.md` is on a single-line statement, so users naturally try the diagnosed line first.

## Suggested fix

Update `Documentation/IgnoringSource.md` to call out multi-line node behavior explicitly with an example showing trailing-on-closing-brace. Alternatively, also accept a trailing directive on the same line as the diagnosed location even when that location is a sub-token within a multi-line statement.

Encountered while running sm 3.0.2 against xc-mcp; took several attempts to find the working placement.



## Summary of Changes

- `Sources/SwiftiomaticKit/Syntax/RuleMask.swift` — `RuleStatusCollectionVisitor.applyDirectives` now scans trailing trivia of every token in the visited `CodeBlockItemSyntax`/`MemberBlockItemSyntax`, skipping tokens that belong to a descendant CBI/MBI. A trailing `// sm:ignore` on the **opening line** of a multi-line statement (e.g. `if x { // sm:ignore Foo`) now suppresses across the whole statement, matching the existing behavior for the closing `}` line.
- `Documentation/IgnoringSource.md` — documents that the directive may sit on the opening or closing line of a multi-line statement, and that interior-line placement only scopes to the inner statement (workaround: move to opening or closing line).
- `Tests/SwiftiomaticTests/Core/RuleMaskTests.swift` — added `trailingIgnoreOnFirstLineOfMultiLineStatement`, `trailingIgnoreOnLastLineOfMultiLineStatement`, and `trailingIgnoreOnMemberDoesNotLeakToSiblings` (regression guard against trailing on a member leaking to the enclosing type).

## Limitations

A trailing directive on an **interior** line of a multi-line node (e.g. inside an if body) only scopes to the inner statement — it cannot bubble up to suppress a rule diagnosed on the outer pattern, because doing so would also leak to unrelated siblings (e.g. one struct member's directive leaking to the rest of the type).
