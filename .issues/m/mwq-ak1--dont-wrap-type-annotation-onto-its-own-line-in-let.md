---
# mwq-ak1
title: Don't wrap type annotation onto its own line in let with ternary RHS
status: completed
type: bug
priority: normal
created_at: 2026-04-27T20:48:49Z
updated_at: 2026-04-30T15:47:44Z
sync:
    github:
        issue_number: "476"
        synced_at: "2026-04-30T16:27:52Z"
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

- [x] Add a failing test reproducing the wrap
- [x] Identify which `.open` is over-extending the type-annotation break's chunk
- [x] Fix precedence so `=` / ternary breaks fire before the type-annotation break
- [x] Verify against existing layout tests



## Summary of Changes

The type-annotation break in `let name: Type = rhs` no longer fires before the `=` / ternary breaks. Verified by `PatternBindingTests.typeAnnotationStaysOnSameLineWithTernaryRHS` (Tests/SwiftiomaticTests/Layout/PatternBindingTests.swift:60), which now passes — output keeps `let newlines: NewlineBehavior = config[…]` inline and wraps at `?` / `:`.
