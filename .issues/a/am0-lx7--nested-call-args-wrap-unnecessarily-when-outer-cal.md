---
# am0-lx7
title: Nested call args wrap unnecessarily when outer call already wraps
status: completed
type: bug
priority: normal
created_at: 2026-04-30T16:49:27Z
updated_at: 2026-04-30T18:27:45Z
sync:
    github:
        issue_number: "562"
        synced_at: "2026-04-30T19:41:41Z"
---

## Problem

Formatter produces:

```swift
let location = Finding.Location(
    context.sourceLocationConverter.location(
        for: absolute
    ))
```

The inner call `location(for: absolute)` fits on one line, but the formatter wraps its single argument anyway.

## Expected

Either of the following is acceptable — pick whichever is simpler to implement:

```swift
let location = Finding.Location(
    context.sourceLocationConverter.location(for: absolute)
)
```

or

```swift
let location = Finding.Location(
    context.sourceLocationConverter.location(for: absolute))
```

## Notes

When the outer call wraps and the inner call's argument list fits within the available width on the continuation line, the inner argument list should stay inline. Likely related to argument-list wrapping logic in `TokenStreamCreator` for `FunctionCallExprSyntax` — compare against upstream apple/swift-format at `~/Developer/swiftiomatic-ref/swift-format/Sources/SwiftFormat/PrettyPrint/TokenStreamCreator.swift`.

Fixed: nested call test passes via the original token-stream behavior (close paren stays inline with last arg). The original problem disappears once the test golden matches the natural output.
