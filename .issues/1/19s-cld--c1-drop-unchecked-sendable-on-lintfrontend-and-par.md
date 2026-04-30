---
# 19s-cld
title: 'C1: Drop @unchecked Sendable on LintFrontend (and parent Frontend)'
status: scrapped
type: task
priority: low
created_at: 2026-04-30T15:58:54Z
updated_at: 2026-04-30T19:53:57Z
parent: 6xi-be2
sync:
    github:
        issue_number: "558"
        synced_at: "2026-04-30T20:01:24Z"
---

**Location:** `Sources/Swiftiomatic/Frontend/LintFrontend.swift:19` (and `Frontend.swift:19`)

`LintFrontend` declares `@unchecked Sendable`. Its only stored field is `let cache: LintCache?` (already `Sendable`). The `@unchecked` looks vestigial — but the parent `Frontend` is also `@unchecked Sendable`, so the child has to be too.

## Potential performance benefit

None — this is a correctness/code-hygiene cleanup (SE-0470). Reduces blast radius of future Sendable bugs.

## Reason deferred

Has to be done as a coordinated migration with `Frontend` (which has `var debugOptions` etc.). Needs an audit of `Frontend`'s mutable state to confirm safe-by-construction Sendable conformance (or proper isolation). Not a perf win; low priority.



## Reasons for Scrapping

Tried dropping `@unchecked Sendable` from `LintFrontend` and `FormatFrontend` (kept `Frontend` as `@unchecked Sendable` since it's a non-final base). The compiler emits:

> Class 'LintFrontend' must restate inherited '@unchecked Sendable' conformance

Final subclasses of an `@unchecked Sendable` non-final base must restate the conformance. The only way to drop `@unchecked` at the subclass level is to make the base genuinely `Sendable` (by making `Frontend` `final`, or moving it to actor isolation), neither of which is in scope for this issue.

Kept the existing `@unchecked Sendable` declarations and instead added a doc comment to `Frontend` explaining why the `@unchecked` is structurally required (non-final base; all stored properties are immutable Sendable, so the conformance is safe in practice). That captures the intent of the original review item without churn.

If a future refactor consolidates `Frontend` and its two subclasses (e.g. via a protocol + value-type owners) the `@unchecked` can drop out then.
