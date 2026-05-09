---
# jfq-6g1
title: Add JSON reporter for sm lint output
status: completed
type: feature
priority: normal
created_at: 2026-05-09T17:43:58Z
updated_at: 2026-05-09T17:56:11Z
sync:
    github:
        issue_number: "686"
        synced_at: "2026-05-09T17:56:53Z"
---

## Context

`xc-mcp` is migrating its `swift_lint` MCP tool from `swiftlint --reporter json` to `sm lint`. The current text format (`path:line:col: warning: [rule] message`) parses cleanly enough, but consumers that build structured tool surfaces (MCP tools, editor integrations, CI annotators) would benefit from a stable JSON schema rather than regex-parsing diagnostic lines.

## Proposal

Add `--reporter json` (or `--format json`) to `sm lint` that emits an array of:

```json
[
  {
    "file": "/abs/path/Foo.swift",
    "line": 12,
    "column": 5,
    "severity": "warning" | "error",
    "rule": "requireCamelCaseIdentifiers",
    "message": "rename the function 'Foo' using lowerCamelCase"
  }
]
```

Bonus: a `--reporter json-summary` that includes counts per rule.

## Why

- Avoids ad-hoc regex parsing in downstream tools (xc-mcp, editor LSP shims).
- Stable contract for CI annotators (GitHub/GitLab style).
- Drop-in replacement path for tools migrating off `swiftlint --reporter json`.

## Workaround for xc-mcp meanwhile

Parse `{path}:{line}:{col}: {severity}: [{rule}] {message}` from stdout. Works, but brittle to format changes.



## Summary of Changes

- Added `--reporter <text|json>` option to `sm lint`. Default `text` preserves existing stderr output; `json` suppresses the text printer and writes a JSON array of findings to stdout.
- Each entry has stable shape `{ file, line, column, severity, rule, message }` with `null` emitted for absent location/rule fields so consumers can rely on a fixed schema.
- Reporter logic lives in `SwiftiomaticKit/Support/JSONReporter.swift` (`JSONLintReporter`) so the encoding is unit-testable.
- New unit tests under `Tests/SwiftiomaticTests/Core/JSONReporterTests.swift` cover empty reports, populated entries, and explicit `null` emission for missing fields.
- CLI surface preserved: existing `lint` flags and behavior are unchanged; `--reporter` is purely additive.

Paired with l84-dng (format JSON reporter) for a consistent machine-readable contract across both subcommands.
