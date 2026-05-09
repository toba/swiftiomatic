---
# l84-dng
title: Emit structured changed-files output from sm format
status: completed
type: feature
priority: normal
created_at: 2026-05-09T17:46:24Z
updated_at: 2026-05-09T17:56:11Z
sync:
    github:
        issue_number: "687"
        synced_at: "2026-05-09T17:56:53Z"
---

## Context

`xc-mcp` is migrating its `swift_format` MCP tool from `swiftformat` (Lockwood) to `sm format`. The old tool surfaced "files that were formatted" by parsing swiftformat's verbose stdout. `sm format -i -r` overwrites in place but doesn't emit a structured list of which files actually changed, so downstream tools have to mtime-diff or hash before/after to reconstruct that.

## Proposal

Add a `--reporter json` (or equivalent) to `sm format` that emits, on stderr or stdout-via-flag, a structured summary consistent with the `sm lint` JSON reporter (see jfq-6g1):

```json
{
  "changed": [
    { "file": "/abs/path/Foo.swift", "bytes_before": 1234, "bytes_after": 1280 }
  ],
  "unchanged": ["/abs/path/Bar.swift"],
  "skipped": [\n    { "file": "/abs/path/Bad.swift", "reason": "unparsable" }\n  ]
}
```

Or a flat list keyed by status if that composes better with `sm lint`'s schema. The key requirement is **schema consistency between `sm lint` and `sm format`** — same envelope shape, same field names where they overlap (e.g. `file`).

## Why

- Lets downstream tools (xc-mcp, editor save-on-format hooks, CI bots) report "formatted N files: …" without re-stat-ing the working tree.
- Pairs with the lint JSON reporter (jfq-6g1) for a single consistent machine-readable contract across both subcommands.
- Stable replacement for callers migrating off swiftformat verbose-output parsing.

## Workaround for xc-mcp meanwhile

Snapshot mtimes (or content hashes) of input paths before/after `sm format -i -r` and diff. Functional but lossy on filesystems with low mtime resolution and adds I/O.



## Summary of Changes

- Added `--reporter <text|json>` option to `sm format`. `json` requires `--in-place` (validated up front) and emits a JSON object on stdout with `changed`, `unchanged`, and `skipped` arrays.
- `changed` entries carry `{ file, bytes_before, bytes_after }`; `skipped` entries carry `{ file, reason }` (currently `unparsable` for parse failures, or the underlying error description for I/O failures).
- Schema matches the lint reporter where overlap exists (`file` is the shared key) and uses snake_case for multi-word numeric fields per the issue example.
- Reporter logic lives in `SwiftiomaticKit/Support/JSONReporter.swift` (`JSONFormatReporter`); FormatFrontend records outcomes per file as it processes them.
- Unit tests in `Tests/SwiftiomaticTests/Core/JSONReporterTests.swift` cover empty reports and the snake_case `changed`/`unchanged`/`skipped` envelope.
- CLI surface preserved: existing `format` flags and behavior are unchanged; `--reporter` is purely additive.
