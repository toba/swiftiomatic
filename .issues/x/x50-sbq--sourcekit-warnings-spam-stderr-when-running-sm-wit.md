---
# x50-sbq
title: SourceKit warnings spam stderr when running `sm` with no arguments
status: completed
type: bug
priority: normal
created_at: 2026-04-12T18:33:56Z
updated_at: 2026-04-12T19:04:00Z
sync:
    github:
        issue_number: "228"
        synced_at: "2026-04-12T19:05:19Z"
---

Running `sm` with no arguments (which defaults to the analyze/lint subcommand) produces dozens of "SourceKit request made outside of rule execution context" warnings to stderr before any useful output appears. The warnings reference `CurrentRule.$allowSourceKitRequestWithoutRule.withValue(true) { ... }`.

This makes the CLI unusable for agents — they see a wall of warnings and can't find the actual output.

- [x] Identify where SourceKit requests fire during default subcommand startup
- [x] Ensure SourceKit requests only happen within rule execution context
- [x] Verify `sm` with no args produces clean output


## Summary of Changes

Wrapped all rule execution calls (`collectInfo`, `validate`, `enrich`, `correct`) in `CurrentRule.$identifier.withValue(type(of: rule).identifier)` so SourceKit requests always have a rule context.

**Files changed:**
- `Sources/SwiftiomaticKit/Suggest/Analyzer.swift` — wrapped `collectInfo`, `validate` (single-pass and collecting), and `enrich` calls
- `Sources/SwiftiomaticCLI/FormatCommand.swift` — wrapped `collectInfo` call in `applyCorrectableLintRules`
- `Sources/SwiftiomaticCLI/SwiftiomaticCLI.swift` — wrapped `collectInfo` call in `Analyze.runFix`

**Root cause:** `Analyzer.runLintRules(on:)` called rules without setting `CurrentRule.identifier`, so rules accessing `file.structureDictionary` or `file.syntaxMap` triggered `sendIfNotDisabled()` with no rule context, emitting the warning for every file.
