---
# 6d8-j44
title: Deduplicate rules in migrate config output
status: in-progress
type: bug
priority: normal
created_at: 2026-04-11T20:34:38Z
updated_at: 2026-04-11T20:35:06Z
sync:
    github:
        issue_number: "194"
        synced_at: "2026-04-11T20:48:50Z"
---

When `swiftiomatic migrate` merges both a `.swiftlint.yml` and `.swiftformat` config, the generated `.swiftiomatic.yaml` contains duplicate rule entries in the enabled/disabled lists.

## Observed

Running `swiftiomatic migrate` on `/Users/jason/Developer/toba/xc-mcp` (which has both `.swiftlint.yml` and `.swiftformat`) produced duplicates:

- `function_parameter_count` appears twice in `disabled`
- `opening_brace` appears twice in `disabled`
- `empty_collection_literal` appears twice in `enabled`
- `first_where` appears twice in `enabled`

This happens because both SwiftLint and SwiftFormat map different source rules to the same swiftiomatic target, and `ConfigMigrator.merge()` concatenates without deduplicating.

## Fix

- [ ] Deduplicate enabled/disabled rule lists in `ConfigMigrator.merge()`
- [ ] Also deduplicate within a single source (e.g. two SwiftLint rules both mapping to `function_parameter_count`)
- [ ] Add a test covering the merge dedup behavior
