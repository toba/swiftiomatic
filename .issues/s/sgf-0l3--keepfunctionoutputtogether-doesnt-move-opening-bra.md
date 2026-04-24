---
# sgf-0l3
title: keepFunctionOutputTogether doesn't move opening brace to output line when wrapping parameters
status: review
type: bug
priority: normal
created_at: 2026-04-24T19:59:21Z
updated_at: 2026-04-24T20:53:19Z
sync:
    github:
        issue_number: "376"
        synced_at: "2026-04-24T20:56:37Z"
---

When `keepFunctionOutputTogether` is `true` and a function signature exceeds the line length, the opening brace should stay with the return type on the same line rather than dropping to its own line.

**Current behavior:**
```swift
fileprivate static func useFailureVariant(name: String, replacement: String) -> Finding.Message
    {
        "replace '\(name)(false, ...)' with '\(replacement)(...)'"
    }
```

**Expected behavior:**
```swift
fileprivate static func useFailureVariant(
    name: String,
    replacement: String
) -> Finding.Message {
    "replace '\(name)(false, ...)' with '\(replacement)(...)'"
}
```

When the full signature doesn't fit on one line, parameters should wrap and the `-> ReturnType {` should remain together on the closing line.

## Tasks
- [x] Investigate how `keepFunctionOutputTogether` interacts with line-length wrapping in TokenStream
- [x] Add failing test case
- [x] Fix the token stream logic
- [x] Verify fix


## Summary of Changes

The `.close` token for the `keepFunctionOutputTogether` group was placed after the signature's last token (return type), leaving the `{` outside the group. The `break(.reset)` before `{` then pushed it to its own line.

Fix: when the function/initializer has a body, place the `.close` after the body's left brace instead, and do so after `arrangeFunctionLikeDecl` so the reversed `afterMap` ordering emits it immediately after `{`.

Changed `visitFunctionDecl` and `visitInitializerDecl` in `TokenStream+Functions.swift`. All 93 related tests pass (FunctionDecl, Initializer, SubscriptDecl, ClosureExpr, MacroDecl, EnumDecl).
