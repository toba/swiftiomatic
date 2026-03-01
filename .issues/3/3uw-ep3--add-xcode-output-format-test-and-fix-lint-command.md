---
# 3uw-ep3
title: Add Xcode output format test and fix lint command output
status: completed
type: bug
priority: normal
created_at: 2026-03-01T00:36:48Z
updated_at: 2026-03-01T00:41:55Z
---

The `lint` command (alias of Analyze) uses `TextFormatter.format()` for text output, which produces human-readable grouped output with confidence markers. This format is NOT parsed by Xcode.

For Xcode Build Phase integration, output must follow `file:line:column: warning: message` format. `DiagnosticFormatter.formatXcode()` exists and produces the correct format, but:

1. It has no tests
2. The `lint` command doesn't use it — it uses TextFormatter instead

## Tasks

- [x] Add `xcode` case to `OutputFormat` enum
- [x] Wire `formatXcode` into the Analyze command for `--format xcode`
- [x] Write test confirming Xcode output format matches what Xcode expects
- [x] Verify tests pass
