---
# dke-1tj
title: 'Wrap ternary: true and false branches each on their own line'
status: in-progress
type: feature
priority: normal
created_at: 2026-04-25T19:59:18Z
updated_at: 2026-04-25T19:59:31Z
sync:
    github:
        issue_number: "415"
        synced_at: "2026-04-25T20:19:37Z"
---

When a ternary expression has to wrap at all, the `?` (true) and `:` (false) portions should each be on their own line. Currently the formatter may keep the true branch on the same line as the condition while wrapping only the false branch.

## Example

Currently produces:

```swift
pendingLeadingTrivia = trailingNonSpace.isEmpty
    ? token.leadingTrivia : token.leadingTrivia + trailingNonSpace
```

Should produce:

```swift
pendingLeadingTrivia = trailingNonSpace.isEmpty
    ? token.leadingTrivia
    : token.leadingTrivia + trailingNonSpace
```

(Indentation in the example is illustrative — the rule is about line-breaking the two branches, not the specific indent.)

## Behavior

- If the ternary fits on one line, leave it alone.
- If wrapping is needed at all, break before `?` AND before `:`, putting the true branch and false branch on separate lines.

## Tasks

- [ ] Locate the rule/layout pass responsible for ternary wrapping
- [ ] Add a failing test reproducing the current single-line-true-branch behavior
- [ ] Implement: if any wrap occurs in a `TernaryExprSyntax`, ensure breaks before both `?` and `:`
- [ ] Verify existing ternary tests still pass
- [ ] Add tests for nested ternaries and ternaries inside larger expressions
