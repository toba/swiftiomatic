---
# zz6-gch
title: 'Layout: collapse else { onto preceding line for guard/if when it fits'
status: completed
type: feature
priority: normal
tags:
    - layout
created_at: 2026-04-25T18:03:36Z
updated_at: 2026-04-25T18:15:07Z
sync:
    github:
        issue_number: "406"
        synced_at: "2026-04-25T18:30:27Z"
---

## Problem

When a `guard` (or `if`) condition wraps onto multiple lines, the `else {` (or trailing `{`) is sometimes pushed to its own line even when it would fit on the line ending with the closing `)` of the condition.

### Current (undesired) layout

```swift
guard let whitespaceEnd = data[offset...].firstIndex(where: { !$0.isWhitespace })
    else {
        return data[offset..<data.endIndex]
    }
```

### Desired layout

```swift
guard let whitespaceEnd = data[offset...].firstIndex(where: { !$0.isWhitespace }) else {
    return data[offset..<data.endIndex]
}
```

When `) else {` (or `) {` for `if`) fits within the configured line length, it should sit on the same line as the closing `)` of the condition rather than being pushed to its own line.

## Scope

- Layout rule (no semantic change)
- Applies to `guard ... else { ... }` and `if ... { ... }` (and likely `else if`, `while`, `for`, `switch` — verify each)
- Only collapse when the resulting line stays within the line length budget
- Should not interfere with intentional wrapping when the keyword line is already at/over budget

## Repro

A real instance exists in `Sources/SwiftiomaticKit/Layout/WhitespaceLinter.swift` (already manually corrected on the working tree — confirm the rule re-produces the correct output on the original).

## Tasks

- [x] Identify the responsible layout rule / break behavior in the layout engine
- [x] Add failing test reproducing the broken `else` placement (guard, then if)
- [x] Implement the collapse-when-fits behavior
- [x] Verify against the WhitespaceLinter.swift instance
- [x] Confirm no regressions in existing layout tests


## Summary of Changes

**Root cause.** The layout token emitted before `else` in a guard statement was `.break(.reset)` with default `.elective` newline behavior, which respects user-entered ("discretionary") newlines. When the source had `... )` then a newline then `else {`, the discretionary newline fired the elective break even though `... ) else {` would have fit on one line. The `.reset` semantics (force a break when on a continuation line) still correctly handle the case where conditions actually wrap.

**Fix.** `Sources/SwiftiomaticKit/Rules/LineBreaks/BeforeGuardConditions.swift:48` — switch the break before `else` to `.elective(ignoresDiscretionary: true)`. Same precedent as the `.reset` break before `{` in `arrangeBracesAndContents` (which is also explicitly `ignoresDiscretionary: true`).

**Behavior matrix:**
| Source | Before | After |
|---|---|---|
| `guard COND else { ... }` (fits) | one line | one line |
| `guard COND` ⏎ `else { ... }` (would fit) | else on new line | one line |
| `guard` wide condition that wraps | wrap + else new line | wrap + else new line |

The last case still works because when conditions wrap, the close break for the condition leaves the line in a continuation state, so `.reset` mustBreak fires regardless of newline behavior.

**Tests added** (`Tests/SwiftiomaticTests/Layout/GuardStmtTests.swift`):
- `collapsesElseOntoConditionLineWhenItFits` — exact reproducer from `WhitespaceLinter.swift:350`.
- `discretionaryElseBreakIgnoredWhenFits` — covers a few smaller variants.

**Verification:**
- Full suite: 2640 passed, 0 failed.
- `if`/`else if` were never affected — that path uses `.space` (not `.break`) before `else` and was already correct.
- Other control-flow keywords (`while`, `for`, `do`, `repeat`, `catch`) don't have a corresponding `cond ⏎ else` shape, so no parallel change needed.
