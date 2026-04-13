---
# 62x-n16
title: UseEarlyExits rule
status: in-progress
type: task
priority: normal
created_at: 2026-04-12T23:57:19Z
updated_at: 2026-04-13T00:20:07Z
parent: shb-etk
sync:
    github:
        issue_number: "248"
        synced_at: "2026-04-13T00:25:20Z"
---

Prefer `guard` for early exits instead of nested `if/else` when the else branch is a simple exit.

**swift-format reference**: `UseEarlyExits.swift` in `~/Developer/swiftiomatic-ref/`

Converts:
```swift
if condition {
    // long block
} else {
    return
}
```
To:
```swift
guard condition else {
    return
}
// long block
```

`redundant_else` handles a related but different case (removing else after an if that already exits). This rule suggests converting the *structure* to guard.

## Checklist

- [ ] Decide scope: lint (warning) or suggest (agent-only)
- [ ] Read reference implementation in swift-format
- [ ] Create rule file with id `use_early_exits`
- [ ] Handle exit keywords: `return`, `throw`, `break`, `continue`
- [ ] Skip when if-block is trivial (e.g. single line) — guard only improves readability for longer blocks
- [ ] Skip `if/else if/else` chains (only simple if/else)
- [ ] Add non-triggering and triggering examples
- [ ] Run `swift run GeneratePipeline`
- [ ] Verify examples pass via RuleExampleTests
