---
# 5jb-q51
title: Add generate-docs CLI subcommand
status: completed
type: feature
priority: normal
created_at: 2026-03-01T00:13:31Z
updated_at: 2026-03-01T00:23:36Z
---

Add a `generate-docs` subcommand that writes rule documentation as markdown files to a specified output directory.

- [ ] Add GenerateDocs command struct
- [ ] Register in SwiftiomaticCLI subcommands
- [ ] Build and test

## Summary of Changes

Added `generate-docs` subcommand to the CLI that writes per-rule markdown documentation plus an index and SourceKit dashboard to a specified output directory. Uses the existing `RuleListDocumentation` infrastructure — the command is ~15 lines wiring it to ArgumentParser.
