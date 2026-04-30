---
# q3p-snb
title: Formatter splits short if-let conditions across lines instead of keeping on one line
status: in-progress
type: bug
priority: normal
created_at: 2026-04-28T00:21:18Z
updated_at: 2026-04-30T03:15:26Z
sync:
    github:
        issue_number: "473"
        synced_at: "2026-04-30T03:34:38Z"
---

## Problem

The formatter wraps a short `if let` chain with multiple bindings across lines and uses an open-brace-on-next-line style, even when the whole condition + opening brace would fit on a single line.

## Actual

```swift
if let value = UInt32(hex, radix: 16),
   let scalar = Unicode.Scalar(value)
{
    set.insert(scalar)
}
```

## Expected

```swift
if let value = UInt32(hex, radix: 16), let scalar = Unicode.Scalar(value) {
    set.insert(scalar)
}
```

The condition fits within the line limit, so it should remain on a single line with the opening brace on the same line.

## Notes

- Likely related to how `if` condition breaks interact with brace placement in `Layout/Tokens/TokenStream+ControlFlow.swift`.
- Compare against upstream apple/swift-format at `~/Developer/swiftiomatic-ref/swift-format` to see how it handles the same input.
- Check `canFit` chunk lengths via `printTokenStream: true` in `LayoutCoordinator`.

## Repro

Format the snippet above and observe the wrap.
