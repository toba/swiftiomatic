---
# wif-qi3
title: UseDocCommentsOnAPI converts trailing enum-case group comments to doc comments
status: completed
type: bug
priority: normal
created_at: 2026-07-06T17:24:30Z
updated_at: 2026-07-06T17:36:45Z
sync:
    github:
        issue_number: "750"
        synced_at: "2026-07-06T17:37:58Z"
---

Default-off rewrite rule UseDocCommentsOnAPI converts a regular group-header comment above the LAST case group in an enum into a /// doc comment.

Repro (enable rule via config, sm 3.14.11):
```swift
enum InfixOperator: String {
    // Comparison operators
    case lt = "<"
    // Boolean operators   <- becomes /// Boolean operators (WRONG)
    case and, or
}
```

Root cause: Sources/SwiftiomaticKit/Rules/Comments/UseDocCommentsOnAPI.swift preserves group headers only via forward-scan isFollowedByConsecutiveMember / isFollowedByConsecutiveCodeItem (~lines 214-234). The last group in a run has no following member, so preserveRegular is false and it converts. Upstream added a backward-continuity check (isPrecededByContinuousPreservedCommentGroup).

Fix: when isFollowedByConsecutive* is false, also preserve when continuous (no blank line) with a preceding preserved group. Gate on the trailing/last-member case.

Ported from: nicklockwood/SwiftFormat docComments fix #2557 (commit 575a010). Default-off so latent/low priority.

- [ ] Add regression test (rule enabled) confirming trailing group header stays a regular comment
- [ ] Add backward group-continuity preservation
- [ ] Confirm green

## Summary of Changes

Added backward group-continuity preservation to UseDocCommentsOnAPI: when `isFollowedByConsecutive*` is false (the comment is on the LAST member of a run), `isPrecededByConsecutivePreservedMember`/`...CodeItem` scan backward through the uninterrupted run (stopping at a blank line) and preserve the header when an earlier member is itself a preserved group header (has a regular comment and is followed by a consecutive member). Added `hasBlankLineAbove` / `hasRegularLineComment` helpers. Applied to both the member and file-scope paths.

- [x] Regression tests `trailingGroupHeaderNotConvertedWhenPreviousGroupPreserved` / `trailingSingleCaseGroupHeaderNotConvertedWhenPreviousGroupPreserved`
- [x] Verified existing `perDeclarationCommentsConvertedEvenIfConsecutive` still passes (per-decl comments make every following member's totalNewlineCount==2, so no preserved anchor exists)
- [x] Full suite green (3476 passed)

Ported from nicklockwood/SwiftFormat docComments fix #2557 (commit 575a010).
