---
# 2q7-lql
title: Formatter leaves dangling trailing commas (`, ), )`) when collapsing a wrapped call passed as a call argument
status: completed
type: bug
priority: normal
created_at: 2026-06-20T19:39:31Z
updated_at: 2026-06-20T20:00:35Z
sync:
    github:
        issue_number: "739"
        synced_at: "2026-06-20T20:01:27Z"
---

## Summary

`sm format` (v3.14.7) produces invalid-looking output with stranded trailing commas before closing parens when it collapses a multi-line call that is itself the sole argument to an outer call (e.g. `array.append(try Foo(...))`).

## Repro

Input:
```swift
func f() throws {
    var built: [Int] = []
    for edit in items {
        built.append(
            try Thing(
                from: edit.citation,
                matchGroupIn: groupsByID,
                matchReferenceIn: referencesByID,
                positionOverride: nil,
            ),
        )
    }
}
```

After `sm format -i`:
```swift
for edit in items {
    try built.append(Thing(
        from: edit.citation, matchGroupIn: groupsByID, matchReferenceIn: referencesByID,
        positionOverride: nil, ), )
}
```

## Problem

The last line is `positionOverride: nil, ), )` — two closing parens each preceded by a stray trailing comma and an odd space (`, ), )`). It compiles (trailing commas are legal) but is ugly and inconsistent: the formatter partially collapsed the wrapper while keeping the inner call's trailing-comma multiline shape, then jammed the outer close onto the same line.

Hoisting `try` out of the call is fine; the trailing-comma handling on collapse is the bug.

## Expected

Either keep the call fully multi-line, or collapse cleanly without dangling commas, e.g. `positionOverride: nil))` (or one comma-per-arg multiline form). Trailing commas should not survive a same-line collapse where they sit immediately before `)`.

## Environment

- swiftiomatic 3.14.7
- Surfaced while formatting `Integrations/CSL/Sources/Models/Citation/CSLCitationGroup.swift` in the Thesis project (`built.append(try CSL.Citation(...))` in a loop).

## Summary of Changes

Root cause: the bug was in the pretty printer (not `NestedCallLayout`, which is off by default). When an inner call is the sole argument of an outer call (`built.append(try Thing(...))`), the brm-7t3 `isSoleCallArgumentOfOuterCall` path sets `ignoreDiscretionary`, dropping the user's per-argument newlines so the call can collapse with its parent. But:

1. The closing-paren break is `elective`, so when the call only *partially* collapsed (args reflowed but didn't all fit on one line), `)` hugged the last argument line.
2. The user's trailing commas were emitted verbatim because `keptAsWritten` (the default `MultilineTrailingCommaBehaviorSetting`) + a non-collection region falls through to the unconditional `else if hasTrailingComma { write "," }` branch in `commaDelimitedRegionEnd`.

Together these produced `positionOverride: nil, ), )` — trailing commas stranded immediately before hugging parens.

### Fix (three coordinated changes)

- **`TokenStream+Collections.swift` — force the closing-delimiter break:** when `ignoreDiscretionary` is in effect *and* the last argument has a trailing comma (and the sole arg isn't an array/dict/closure literal), force `.close(mustBreak:)`. This makes the collapse all-or-nothing: the whole call fits on one line, or it stays wrapped with `)` on its own line so each trailing comma is followed by a newline. Gated on a trailing comma so the common no-comma case still hugs (`for: absolute))`).
- **`LayoutCoordinator.swift` — drop the comma on single-line collapse:** in the `keptAsWritten`/non-collection branch of `commaDelimitedRegionEnd`, only write the preserved trailing comma when the region is still multiline. A region that collapsed to one line drops the now-stray comma. (whitespace-only mode unchanged.)
- **`TokenStream+Collections.swift` — size-0 break after the last comma:** the `.break(.same)` after the *last* argument's trailing comma only sits before the close break, so it never needs a separating space; using size 0 removes the residual `b: 2 )` space on collapse without affecting newline behavior.

### Result

```swift
// before:  positionOverride: nil, ), )
// after (partial collapse):
try built.append(Thing(
    from: edit.citation, matchGroupIn: groupsByID, matchReferenceIn: referencesByID,
    positionOverride: nil,
),
)
// after (full collapse): foo(Bar(a: 1, b: 2))
```

No dangling commas, idempotent output.

### Tests

Added `nestedCallCollapseDoesNotStrandTrailingCommas` and `nestedCallFullCollapseDropsTrailingComma` to `CommaTests`. Full suite green (3466 passed). Verified end-to-end on the issue's exact repro via the debug `sm` binary.
