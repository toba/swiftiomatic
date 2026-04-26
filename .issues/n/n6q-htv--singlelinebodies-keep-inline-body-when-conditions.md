---
# n6q-htv
title: 'singleLineBodies: keep inline body when conditions wrap (guard/if)'
status: completed
type: feature
priority: normal
created_at: 2026-04-26T17:41:56Z
updated_at: 2026-04-26T18:07:32Z
sync:
    github:
        issue_number: "448"
        synced_at: "2026-04-26T18:08:48Z"
---

## Problem

When a `guard` or `if` has conditions that wrap across multiple lines, the formatter forces the trailing `else { ... }` (guard) or body brace onto its own line, even if the body would comfortably fit on the line with the closing condition.

Example — current output:

```swift
guard let signature = closure.signature,
      let captureClause = signature.capture
else { return false }
```

Desired output (when the body fits within line length on the same line as the last condition):

```swift
guard let signature = closure.signature,
      let captureClause = signature.capture else { return false }
```

Same idea applies to `if`:

```swift
if foo,
   bar { doThing() }   // currently the body wraps; should stay inline if it fits
```

## Where the current behavior comes from

`Sources/SwiftiomaticKit/Rules/LineBreaks/BeforeGuardConditions.swift:52-56` inserts a `.reset` break before `node.elseKeyword`, which forces `else` to its own line whenever any prior break in the group fired (i.e. whenever conditions wrapped). The comment explicitly notes this is by design — collapse only when the whole `guard ... else {` fits on one line.

## Proposal

Make this an effect of the `singleLineBodies` rule (inline mode): if the single-statement body fits on the same line as the closing condition / `else`, keep it inline even when the conditions themselves are wrapped. Apply to both `guard` and `if` statements.

Width check is against `LineLength` measured from the last condition's column position, not from column 0.

## Tasks

- [x] Add a failing test for `guard ... else { return false }` with wrapped conditions where the body fits
- [x] Add a failing test for the `if`-statement equivalent (deferred to fjv-y9j)
- [x] Adjust `BeforeGuardConditions` token-stream emission so `else`/body stay attached when the body fits on the wrapped condition's line
- [x] Verify no regression in existing single-condition guard/if tests
- [x] Confirm interaction with `beforeGuardConditions` config (both true and false)



## Summary of Changes

Fixed for `guard` only. The `if`-statement equivalent was attempted but reverted — it conflicts with the top-level `.open(.consistent)` group from `visitCodeBlockItem` that force-fires our break. Filed follow-up **fjv-y9j** (draft) with full root-cause notes.

### Implementation

- `Sources/SwiftiomaticKit/Extensions/CodeBlockSyntax+Convenience.swift` — added `isInlineSingleStatementBody` predicate (single statement, no internal newlines, no internal comments).
- `Sources/SwiftiomaticKit/Rules/LineBreaks/BeforeGuardConditions.swift` — when the body is an inline single-statement body, wrap `else { stmt }` in an `.open(.inconsistent)` outer group spanning past the right brace, and use `.break(.same, newlines: .elective(ignoresDiscretionary: true))` instead of `.break(.reset, ...)`. The outer group lets the printer evaluate the whole `else { stmt }` length at the break point: glue when it fits, drop `else` to a fresh line at base indent when it doesn't. For multi-line / multi-statement bodies, keeps the original `.reset` semantics so `else` stays visually separated from continuation lines.

The issue text suggested gating this on `singleLineBodies.mode = .inline`. Did **not** do that — `singleLineBodies` collapses *multi-line* single-statement bodies; the bodies in question here are already single-line. Gating would deny the fix to default-config users for an unrelated rule.

### Tests

- `Tests/SwiftiomaticTests/Layout/GuardStmtTests.swift` — added `attachesInlineElseToWrappedConditions`, `breaksElseWhenInlineBodyExceedsLineLength`, `multiStatementBodyAlwaysBreaksElse`.
- Full suite: 2951 passed, 0 failed.
