---
# mgk-9n9
title: Don't wrap type annotation in let with function-call RHS
status: completed
type: bug
priority: normal
created_at: 2026-04-30T04:38:04Z
updated_at: 2026-04-30T05:15:01Z
sync:
    github:
        issue_number: "535"
        synced_at: "2026-04-30T05:51:02Z"
---

## Problem

Swiftiomatic wraps the type annotation onto its own line in a `let` declaration when the RHS is a function call, producing:

```swift
let message:
    Finding.Message = .removeRedundantExtensionACL(keyword: extensionModifier.name.text)
```

## Expected

The type annotation should stay with the identifier; wrap the function call arguments instead:

```swift
let message: Finding.Message = .removeRedundantExtensionACL(
    keyword: extensionModifier.name.text)
```

## Notes

Same underlying class as mwq-ak1 (type-annotation wrap firing before higher-priority breaks). Type-annotation break should be lower priority than function-call argument breaks, ternary breaks, and assignment `=`.

See CLAUDE.md "Layout & Break Precedence". Likely `arrangeAssignmentBreaks` / type-annotation token emission.

## Tasks

- [x] Add a failing test reproducing the wrap
- [x] Identify which `.open` is over-extending the type-annotation break's chunk
- [x] Fix precedence so call-arg breaks fire before the type-annotation break
- [x] Verify against existing layout tests


## Summary of Changes

`Sources/SwiftiomaticKit/Layout/Tokens/TokenStream+Bindings.swift` `visitPatternBinding`:

1. When the RHS has its own inner break points (ternary, function call, member-access, subscript call, sequence, infix operator, closure), close the type-annotation continuation break right after the type — keeps the `:` chunk short so the type-annotation break is a last-resort wrap.
2. In the same case, emit a simple `.break(.continue)` for `=` (skip `arrangeAssignmentBreaks` entirely) so the `=` break has no surrounding `.open`/`.close` group. The `=` chunk is then bounded by the next inner break, letting call-arg / ternary / member-access breaks fire first.

`Tests/SwiftiomaticTests/Layout/PatternBindingTests.swift`:
- Added `typeAnnotationStaysOnSameLineWithFunctionCallRHS` using the exact reproducer at lineLength 80.

Verified: PatternBindingTests 5/5 passed (0.037s).
