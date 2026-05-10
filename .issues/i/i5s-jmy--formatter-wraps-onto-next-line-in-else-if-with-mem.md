---
# i5s-jmy
title: Formatter wraps '{' onto next line in else-if with member-access condition
status: completed
type: bug
priority: normal
created_at: 2026-05-10T14:24:05Z
updated_at: 2026-05-10T15:14:45Z
sync:
    github:
        issue_number: "690"
        synced_at: "2026-05-10T15:59:46Z"
---

The formatter is moving the opening brace `{` of an `else if` branch onto its own line when the condition contains a member-access chain (e.g. `rawLineLengths.count`).

## Repro

Input (and desired output):

```swift
if lineIndex < 0 {
    lineIndex = 0
} else if lineIndex >= rawLineLengths.count {
    lineIndex = rawLineLengths.count - 1
}
```

Actual output:

```swift
if lineIndex < 0 {
    lineIndex = 0
} else if lineIndex >= rawLineLengths.count
{
    lineIndex = rawLineLengths.count - 1
}
```

The condition fits well within the line limit, so no wrap should occur. The `{` should stay on the same line as the condition.

## Suspected area

Likely in the break/group placement around `else if` condition + opening brace in the pretty printer (`TokenStreamCreator`/layout). The contextual break introduced by the member-access chain (`rawLineLengths.count`) appears to be firing before the open-brace token instead of staying inline. See the "Layout & Break Precedence" notes in `CLAUDE.md` — particularly `maybeGroupAroundSubexpression` and member-access chain handling — and compare against upstream `apple/swift-format` behavior on the same input.

## Tasks

- [x] Add a failing pretty-printer test reproducing the wrap
- [x] Identify which break/group around the `else if` condition over-extends
- [x] Fix and confirm no regressions in full suite


## Reasons for Scrapping

Duplicate of rua-efw, which already fixed this. Verified against current source:

- `IfStmtTests/ifElseStatement_keepsInlineBraceWhenFits` passes.
- Running current `sm format -i` on the user's actual file (`thesis/Core/Sources/XML/XMLDecoder.swift`, which currently shows `{` wrapped onto its own line) restores `{` to the same line as the condition.

The broken layout in that file was written by an older `sm` predating rua-efw's fix; the file just hasn't been re-formatted since. No code change needed — re-running the formatter on the affected file is sufficient.


## Summary of Changes

Root cause was *not* in the per-IfExpr conditions group, but in the chain-wrapping consistent group placed by `visitCodeBlockItem` (TokenStream+MembersAndBlocks.swift). That `.open(.consistent)` spans the *entire* if statement — conditions AND bodies — and was previously skipped only for a bare `if` with an inline body.

When `LayoutSingleLineBodies` (inline mode) collapses an `else if` branch's single-statement body to inline form while the outer branch's body is multi-statement, the outer body's mandatory `.soft` newline forces the consistent group. Per `LayoutCoordinator.emitToken` (line 210), forcing a `.consistent` group pushes `true` onto `forceBreakStack`, which then turns every `.same` break inside the group into a mandatory break — including the inline-body break before the inlined `{` (`.break(.same, size: 1, .elective(ignoresDiscretionary: true))` from `visitIfExpr`'s `attachInlineBody` path). That dropped `{` onto its own line.

Fix: extend the skip in `visitCodeBlockItem` via a new helper `ifChainMixesInlineAndMultiLineBodies(_:)` that walks the if/else-if/else chain and reports whether at least one branch has an inline single-statement body and at least one branch is multi-statement / multi-line. When the chain mixes both, the consistent wrapper is omitted; per-branch consistent grouping (per-IfExpr conditions group when `count > 1`) and the body-internal `.break(.open(.block))` continue to handle wrapping correctly.

Files changed:
- `Sources/SwiftiomaticKit/Layout/Tokens/TokenStream+MembersAndBlocks.swift` — extracted `isInlineSingleStmtBody(_:)` helper, added `ifChainMixesInlineAndMultiLineBodies(_:)`, extended skip predicate.
- `Tests/SwiftiomaticTests/Layout/IfStmtTests.swift` — added `ifElseStatement_keepsInlineElseIfWhenOuterBodyIsMultiLine` regression test.

Verified:
- Full suite: 3368 passed, 0 failed.
- Manual repro on `thesis/Core/Sources/XML/XMLDecoder.swift` with the thesis `swiftiomatic.json` config: the `} else if lineIndex >= rawLineLengths.count\n{` pattern is now reformatted back to the same-line-brace form.
