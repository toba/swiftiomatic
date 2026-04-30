---
# fo7-8mu
title: 'switch case: wrapped patterns should align with first pattern, not indent'
status: completed
type: bug
priority: normal
created_at: 2026-04-30T16:51:20Z
updated_at: 2026-04-30T18:27:41Z
sync:
    github:
        issue_number: "564"
        synced_at: "2026-04-30T19:41:42Z"
---

## Problem

Formatter produces:

```swift
switch piece {
    case let .lineComment(t),
        let .blockComment(t),
        let .docBlockComment(t):
        text = t
    default: continue
}
```

Wrapped patterns in a multi-pattern `case` are indented as continuations, which makes them visually collide with the case body indentation.

## Expected

Like wrapped `guard`/`if` conditions, subsequent patterns should align under the first pattern (after `case `):

```swift
switch piece {
    case let .lineComment(t),
         let .blockComment(t),
         let .docBlockComment(t):
        text = t
    default: continue
}
```

## Notes

Likely lives in token-stream construction for `SwitchCaseLabelSyntax` / case items. Compare against upstream apple/swift-format at `~/Developer/swiftiomatic-ref/swift-format/Sources/SwiftFormat/PrettyPrint/TokenStreamCreator.swift`. The alignment mechanism used by `guard`/`if` conditions (see `BeforeGuardConditions` and related layout in `Sources/SwiftiomaticKit/Layout/`) is the model to mirror.

Fixed: switch case multi-pattern alignment works with AlignWrappedConditions=true. The colon stays glued to the last pattern, achieved via .open(.consistent) closed before colon and per-item alignment break-closes also placed before colon.
