---
# vw7-qtf
title: 'switch case: inline block rule should inline single-statement body even with wrapped patterns'
status: completed
type: bug
priority: normal
created_at: 2026-04-30T16:52:43Z
updated_at: 2026-04-30T18:27:43Z
blocked_by:
    - fo7-8mu
sync:
    github:
        issue_number: "559"
        synced_at: "2026-04-30T19:41:42Z"
---

## Problem

Related to `fo7-8mu` (switch case wrapped pattern alignment).

When the inline-block rule is active, a switch case whose body is a single short statement should keep the body on the same line as the case label — even when the case has multiple patterns that wrap across lines.

Currently the formatter produces (after `fo7-8mu` is fixed):

```swift
switch piece {
    case let .lineComment(t),
         let .blockComment(t),
         let .docBlockComment(t):
        text = t
    default: continue
}
```

## Expected

```swift
switch piece {
    case let .lineComment(t),
         let .blockComment(t),
         let .docBlockComment(t): text = t
    default: continue
}
```

The single-statement body `text = t` should remain inline after the colon, matching the existing inline-block behavior for `default: continue`.

## Notes

Depends on `fo7-8mu` being resolved first (pattern alignment). The inline-block rule already handles single-pattern cases correctly — extend it to multi-pattern cases. Look at the inline-block rule's eligibility check in `Sources/SwiftiomaticKit/Rules/` to ensure wrapped patterns don't disqualify the case from inlining its body.

Fixed: switch case inline body now stays on the same line as colon when patterns wrap and body fits. Required fixing LayoutCoordinator's continuation-state propagation: alignment-kind close breaks now skip setting currentLineIsContinuation in the can-fit path, so the body's reset break before .break(.open) doesn't fire.
