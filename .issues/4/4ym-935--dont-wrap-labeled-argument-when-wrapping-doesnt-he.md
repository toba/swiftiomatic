---
# 4ym-935
title: Don't wrap labeled argument when wrapping doesn't help fit
status: completed
type: bug
priority: normal
created_at: 2026-05-02T16:50:24Z
updated_at: 2026-05-02T17:17:51Z
sync:
    github:
        issue_number: "631"
        synced_at: "2026-05-02T17:32:31Z"
---

When a labeled call argument's value would still exceed the print width even after wrapping to its own line, the formatter should leave it inline rather than wrapping.

Example with print width 100:

```swift
let namesAndSchemas = try Row.fetchAll(
    db,
    sql:
        "SELECT type, name, tbl_name, sql FROM sqlite_schema WHERE type = 'table' AND tbl_name IN (\\(placeholders))",
    arguments: StatementArguments(tableNames),
)
```

The wrapped form (indent + string) is *longer* than the inline form (`sql: "..."`). It should produce instead:

```swift
let namesAndSchemas = try Row.fetchAll(
    db,
    sql: "SELECT type, name, tbl_name, sql FROM sqlite_schema WHERE type = 'table' AND tbl_name IN (\\(placeholders))",
    arguments: StatementArguments(tableNames),
)
```

There's an existing heuristic in `LayoutCoordinator.swift` (`breakSavesEnough`) that already implements this idea for `.continue` breaks: only fire the break if it saves >= 8 columns. Need to investigate why it's not catching this case and tighten it.

## Tasks
- [x] Add a failing layout test reproducing the case
- [x] Diagnose why `breakSavesEnough` doesn't apply
- [x] Fix and confirm full suite passes

## Summary of Changes

Two coordinated changes:

1. **`Sources/SwiftiomaticKit/Layout/Tokens/TokenStream+Collections.swift`** — in `arrangeAsFunctionCallArgument`, the break after a labeled argument's colon now uses `.elective(ignoresDiscretionary: true)`. A user-inserted newline between `label:` and its value no longer forces a wrap; the pretty printer's normal fitting logic decides whether to wrap.

2. **`Sources/SwiftiomaticKit/Layout/LayoutCoordinator.swift`** — the existing `breakSavesEnough` 8-column threshold (only fire a continuation break whose chunk would still overflow when the wrap saves at least N columns) now reads from a new configuration setting instead of being hardcoded.

3. **New setting** `Sources/SwiftiomaticKit/Rules/LineBreaks/MinimumWrapSavings.swift` — `Int`, default `8`, in the `lineBreaks` config group. Documents the threshold and lets users tune wrap aggressiveness for over-long chunks.

4. **Test added**: `labeledArgumentStaysInlineWhenWrapDoesntHelp` in `FunctionCallTests.swift`, covering the user's exact `Row.fetchAll(sql: "SELECT ...")` case at `linelength: 100` with 4-space indent.

5. **Test updated**: `discretionaryLineBreakAfterColon` in `FunctionCallTests.swift` — its expected output documented the OLD behavior of preserving source newlines after labeled-arg colons; updated to reflect the new behavior.

Tuple-type element labels (`(foo: Foo, bar: Long, baz: Baz)`) were not changed; another agent is working in that area.
