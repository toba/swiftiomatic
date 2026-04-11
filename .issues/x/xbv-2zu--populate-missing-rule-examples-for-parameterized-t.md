---
# xbv-2zu
title: Populate missing rule examples for parameterized testing
status: completed
type: task
priority: normal
created_at: 2026-04-11T20:15:06Z
updated_at: 2026-04-11T20:29:54Z
sync:
    github:
        issue_number: "193"
        synced_at: "2026-04-11T20:31:36Z"
---

Several rules have empty `nonTriggeringExamples` and `triggeringExamples` arrays. The new parameterized `RuleExampleTests` (from 8ak-rh2) skips rules with no examples, so these rules have no example-validation coverage.

## TODO

- [x] Identify all rules where both `nonTriggeringExamples` and `triggeringExamples` are empty
- [x] For each, add at least one non-triggering and one triggering example
- [x] Some rules may not be amenable to this approach (e.g. rules that require file-on-disk, multi-file context, or runtime state) — document those as exceptions

## Context

`RuleExampleTests.swift` filters to rules that:
- Don't require SourceKit
- Don't require compiler arguments
- Don't require cross-file collection
- Have at least one example

Rules missing examples fall through the last filter and get zero coverage from the parameterized test.


## Summary of Changes

Out of ~319 registered rules, only **2** have empty examples:

1. **FileNameNoSpaceRule** (`file_name_no_space`) — checks file names for whitespace
2. **FileNameRule** (`file_name`) — checks file names match a declared type

Both are file-path-dependent rules that inspect `file.path` rather than AST content. The standard parameterized test infrastructure creates `SwiftSource` objects either in-memory (no path) or with UUID-named temp files, so these rules can never trigger from inline code examples.

### Exceptions documented

Both rules are exceptions to parameterized example testing because:
- They depend on the **file name**, not the file contents
- Both already have comprehensive dedicated test suites using fixture files on disk:
  - `FileNameNoSpaceRuleTests` (5 tests)
  - `FileNameRuleTests` (23 tests)
- Added `requiresFileOnDisk = true` to both rules to correctly mark them

All other ~317 rules already have examples (either inline or in `+examples.swift` extension files) and are covered by `RuleExampleTests`.
