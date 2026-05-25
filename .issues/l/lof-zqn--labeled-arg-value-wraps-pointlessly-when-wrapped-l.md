---
# lof-zqn
title: Labeled-arg value wraps pointlessly when wrapped line still overflows but chunk alone fits
status: completed
type: bug
priority: normal
created_at: 2026-05-25T18:52:11Z
updated_at: 2026-05-25T19:10:52Z
sync:
    github:
        issue_number: "706"
        synced_at: "2026-05-25T19:11:18Z"
---

## Problem

The `MinimumWrapSavings` heuristic in `LayoutCoordinator` only applies when the chunk *alone* exceeds the line length (`chunkAfterBreak > maxLineLength`). When a labeled argument's value is shorter than the line limit on its own, but `continuationIndent + value` still overflows, the wrap fires even though it shifts the content only a column or two — pointless indentation.

Works (chunk alone > limit, 4ym-935):
```
sql: "SELECT type, name, tbl_name, sql FROM sqlite_schema WHERE type = 'table' AND tbl_name IN (\\(placeholders))",
```

Broken (chunk fits but indent+chunk overflows):
```
sql:
    "SELECT sql_name, schema, json(table_info) AS table_info FROM \\(ShadowTableSchema.sqlName)",
```
and
```
sql:
    "SELECT dflt_value, pk, name, \\"notnull\\", type FROM pragma_table_info(?)",
```

## Fix

Apply the savings heuristic whenever the *wrapped* line would still overflow (`postWrapEndColumn > maxLineLength`), not just when the chunk alone exceeds the limit.

Repro file: thesis Core/Sources/CloudKit/SyncEngine/SyncEngine+Lifecycle.swift


## Summary of Changes

Scoped the "keep over-long value inline" behavior to labeled function-call argument values that are a single-line string literal, where wrapping below `label:` is pointless.

- `Token.swift`: added `PrinterControlKind.keepInlineIfWrapPointless` — a one-shot marker consumed by the next continuation break.
- `TokenStream+Collections.swift` (`arrangeAsFunctionCallArgument`): emit the marker before the post-colon break when the argument value is a single-line string literal (`.stringQuote`).
- `LayoutCoordinator.swift`: when the flag is set and the chunk fits on its own line but the current indentation (plus the continuation indent the break itself adds) still pushes it past the limit, only fire the break if it dedents by at least one indentation unit. Ordinary continuation breaks (assignments, `await`, key paths, attributes) are unaffected because the flag is only set for string-literal argument values.

The earlier global-heuristic attempt regressed 16 tests (assignment/await/keypath/accessor/param-pack wraps) because the savings value alone can't distinguish a pointless string relocation from a wrap that enables a further break cascade. Scoping via the printer-control flag fixes the three reported `sql:` cases (verified end-to-end on thesis `SyncEngine+Lifecycle.swift`) with the full 3395-test suite green.

Added `FunctionCallTests.labeledArgumentStaysInlineWhenWrappedLineStillOverflows`.
