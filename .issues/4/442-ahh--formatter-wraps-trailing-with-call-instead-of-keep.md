---
# 442-ahh
title: Formatter wraps trailing .with() call instead of keeping single chained call on one line
status: ready
type: bug
priority: high
created_at: 2026-04-28T00:20:06Z
updated_at: 2026-04-28T00:20:06Z
sync:
    github:
        issue_number: "477"
        synced_at: "2026-04-28T02:39:59Z"
---

## Problem

The pretty printer wraps the second `.with()` call in a member-access chain when the entire chain would fit on the line if kept together with the first `.with()` call.

## Expected output

```swift
replacement.typeAnnotation = .init(
    type: type.with(\.leadingTrivia, .space).with(\.trailingTrivia, .space)
)
```

## Actual output

```swift
replacement.typeAnnotation = .init(
    type: type.with(\.leadingTrivia, .space).with(
        \.trailingTrivia,
        .space
    ))
```

## Notes

- The argument to `.init(...)` (`type.with(...).with(...)`) fits on a single line within the indented `.init` call body.
- The formatter is breaking inside the second `.with(...)` call's argument list AND splitting its arguments one-per-line, instead of keeping the chain intact.
- The trailing `))` on its own being collapsed is a separate symptom of the same wrap decision.
- Likely related to break precedence / chunk bounding around member-access chains in function-call arguments. See CLAUDE.md "Layout & Break Precedence" — suspect `maybeGroupAroundSubexpression` or `isMemberAccessChain` handling when the chain itself is an argument to an outer call.
- Compare to apple/swift-format at `~/Developer/swiftiomatic-ref/swift-format` to see how upstream handles this case.

## Tasks

- [ ] Add a failing layout test reproducing the actual vs expected output
- [ ] Identify where chunk bounding goes wrong (dump token stream; check `.open` placement around the chained `.with(...)` calls)
- [ ] Compare to upstream behavior in `TokenStreamCreator.swift`
- [ ] Fix and verify test passes; run broader formatter test suite for regressions
