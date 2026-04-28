---
# mwq-ak1
title: Don't wrap type annotation onto its own line in let with ternary RHS
status: in-progress
type: bug
priority: normal
created_at: 2026-04-27T20:48:49Z
updated_at: 2026-04-27T20:55:41Z
sync:
    github:
        issue_number: "476"
        synced_at: "2026-04-28T02:39:59Z"
---

## Problem

Swiftiomatic is wrapping the type annotation onto its own line in a `let` declaration when the RHS is a ternary, producing:

```swift
let newlines:
    NewlineBehavior = config[KeepFunctionOutputTogether.self]
        ? .elective(ignoresDiscretionary: true)
        : .elective
```

## Expected

The type annotation should stay with the identifier, and the ternary should wrap on the `?`/`:` operators:

```swift
let newlines: NewlineBehavior = config[KeepFunctionOutputTogether.self]
        ? .elective(ignoresDiscretionary: true)
        : .elective
```

## Notes

The break between `let newlines:` and `NewlineBehavior` should not fire — wrapping the type annotation is a last-resort behavior and should be lower priority than wrapping at the assignment `=` or at the ternary `?`/`:` breaks.

Likely a break-precedence issue in `arrangeAssignmentBreaks` / type-annotation token emission. See CLAUDE.md "Layout & Break Precedence" section.

## Tasks

- [ ] Add a failing test reproducing the wrap
- [ ] Identify which `.open` is over-extending the type-annotation break's chunk
- [ ] Fix precedence so `=` / ternary breaks fire before the type-annotation break
- [ ] Verify against existing layout tests
