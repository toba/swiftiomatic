---
# sgf-0l3
title: keepFunctionOutputTogether doesn't move opening brace to output line when wrapping parameters
status: in-progress
type: bug
priority: normal
created_at: 2026-04-24T19:59:21Z
updated_at: 2026-04-24T20:41:19Z
sync:
    github:
        issue_number: "376"
        synced_at: "2026-04-24T20:43:39Z"
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
- [ ] Investigate how `keepFunctionOutputTogether` interacts with line-length wrapping in TokenStream
- [ ] Add failing test case
- [ ] Fix the token stream logic
- [ ] Verify fix
