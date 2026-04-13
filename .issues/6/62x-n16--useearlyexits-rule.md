---
# 62x-n16
title: UseEarlyExits rule
status: completed
type: task
priority: normal
created_at: 2026-04-12T23:57:19Z
updated_at: 2026-04-13T00:27:33Z
parent: shb-etk
sync:
    github:
        issue_number: "248"
        synced_at: "2026-04-13T00:55:42Z"
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

- [x] Decide scope: lint (warning, opt-in, not correctable)
- [x] Read reference implementation in swift-format
- [x] Create rule file with id `use_early_exits`
- [x] Handle exit keywords: `return`, `throw`, `break`, `continue`
- [x] Skip when if-block is trivial (3 or fewer statements)
- [x] Skip `if/else if/else` chains (only simple if/else)
- [x] Add non-triggering and triggering examples
- [x] Run `swift run GeneratePipeline`
- [x] Verify examples pass via RuleExampleTests


## Summary of Changes

Created `UseEarlyExitsRule` (lint, opt-in, not correctable) at `Rules/ControlFlow/Conditionals/`. Flags if/else blocks where the else ends with return/throw/break/continue and the true branch has >3 statements. Skips if/else-if chains.
