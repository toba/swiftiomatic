---
# tbp-z82
title: 'migrate: wrong rename mappings and missing .swiftformat config'
status: completed
type: bug
priority: normal
created_at: 2026-04-11T23:32:29Z
updated_at: 2026-04-11T23:42:52Z
sync:
    github:
        issue_number: "198"
        synced_at: "2026-04-11T23:48:39Z"
---

## Problem

Two issues with `sm migrate`:

### 1. Wrong SwiftLint rename mappings

Every entry in `swiftlintRenamed` is incorrect. These rules exist in Swiftiomatic with the same ID but the renamed dict catches them before the exact-match check:

- `empty_count` → wrongly renamed to `empty_collection_literal` (exists as `empty_count`)
- `syntactic_sugar` → wrongly renamed to `empty_collection_literal` (exists as `syntactic_sugar`)
- `shorthand_operator` → wrongly renamed to `shorthand_argument` (exists as `shorthand_operator`)
- `statement_position` → wrongly renamed to `opening_brace` (exists as `statement_position`)
- `large_tuple` → wrongly renamed to `function_parameter_count` (exists as `large_tuple`)
- `contains_over_first_not_nil` → wrongly renamed to `first_where` (exists as `contains_over_first_not_nil`)
- `redundant_self_in_closure` → wrongly renamed to `explicit_self` (is a deprecated alias for `redundant_self` in Swiftiomatic, handled by alias resolution)
- `unused_capture_list` → wrongly renamed to `unused_closure_parameter` (removed from SwiftLint, compiler handles it)

### 2. Missing .swiftformat config migration

The parser stores all `rawOptions` from `.swiftformat` but the migrator only handles `indent`, `maxWidth`, `commas`, and `swiftVersion`. Options like `--else-position`, `--self`, `--wrap-arguments` etc. are silently dropped. These should map to Swiftiomatic format settings or per-rule configs.

## Tasks

- [x] Remove all wrong entries from `swiftlintRenamed`
- [x] Move `unused_capture_list` to `swiftlintRemoved`
- [x] Add .swiftformat option → Configuration format setting mappings
- [x] Add .swiftformat option → per-rule config mappings
- [x] Test with xc-mcp and thesis config files
- [x] Fix 3 wrong SwiftFormat target IDs (sorted_imports, number_formatting, redundant_raw_values)
- [x] Fix stale sorted_imports reference in DiagnosticDeduplicator
- [x] Add 9 missing SwiftLint rename mappings
- [x] Add 2 missing SwiftFormat mappings (isEmpty, privateStateVariables)

## Reference

- SwiftLint ref: ~/Developer/swiftiomatic-ref/SwiftLint
- Swiftiomatic has 320 rules, most matching SwiftLint IDs exactly
- `RedundantSelfRule` already has `redundant_self_in_closure` as deprecated alias


## Summary of Changes

Fixed `sm migrate` to produce correct rule mappings and carry through `.swiftformat` configuration.

**Rule mapping fixes:**
- Removed 8 wrong entries from `swiftlintRenamed` (rules that exist with the same ID or are deprecated aliases)
- Added `unused_capture_list` to removed rules (compiler handles it)
- Added 9 correct SwiftLint rename mappings (e.g. `operator_usage_whitespace` → `operator_usage_spacing`)
- Fixed 3 wrong SwiftFormat targets (`sorted_imports` → `sort_imports`, etc.)
- Added 2 missing SwiftFormat mappings (`isEmpty`, `privateStateVariables`)
- Fixed stale `sorted_imports` in DiagnosticDeduplicator

**Config migration:**
- Added `--else-position` → `formatLineBreakBeforeControlFlowKeywords`
- Added `--wrap-arguments` → `formatLineBreakBeforeEachArgument`
- Added per-rule config migration from `.swiftformat` raw options (`--self`, `--indent-case`, `--pattern-let`, `--import-grouping`, `--empty-braces`, `--closing-paren`, `--strip-unused-args`)
- Fixed merge to propagate additional format settings and rule configs

**Results:** xc-mcp: 69→80 mapped, 16→5 unmapped. thesis: 83 mapped, 5 unmapped.
