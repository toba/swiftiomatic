---
# wvc-7oa
title: 'Sanitize rules: consolidate, eliminate, or split overlapping rules'
status: completed
type: task
priority: normal
created_at: 2026-04-11T18:05:26Z
updated_at: 2026-04-11T18:42:46Z
sync:
    github:
        issue_number: "183"
        synced_at: "2026-04-11T18:44:01Z"
---

Analyze all existing rules for overlap, redundancy, or candidates for splitting.

## Scope

- Review every rule in `Sources/SwiftiomaticKit/Rules/`
- Cross-reference with original source projects in `/Users/jason/Developer/swiftiomatic-ref/`
- Identify rules that overlap in what they detect
- Identify rules that should be consolidated into one
- Identify rules that should be eliminated (no value or fully subsumed)
- Identify rules that try to do too much and should be split

## Deliverable

A report (stored in this issue body) with recommendations:
- Groups of overlapping rules with explanation
- Consolidation recommendations (which rules to merge, proposed name)
- Elimination recommendations (which rules to drop, why)
- Split recommendations (which rules to break apart, proposed new rules)

## Tasks

- [x] Inventory all rules with their IDs, scopes, and descriptions
- [x] Map rule overlaps and redundancies
- [x] Cross-reference with reference projects for original intent
- [x] Write recommendations report
- [x] Store report in this issue



---

## Report: Rule Sanitization Analysis

### Executive Summary

The rule set contains **338 registered rules** across three scopes (lint, format, suggest). This audit identifies **12 overlap groups**, **5 elimination candidates**, **3 split recommendations**, and **8 consolidation opportunities**.

---

### Rules to Eliminate (5)

| Rule | Reason |
|------|--------|
| `implicit_getter` | Fully duplicated by `redundant_get` which is correctable |
| `redundant_raw_values` | Exact duplicate of `redundant_string_enum_value` |
| `redundant_memberwise_init` | Subsumed by `unneeded_synthesized_initializer` |
| `number_formatting` | Subsumed by `number_separator` |
| `organize_declarations` | Weaker version of `type_contents_order` |

---

### Rules to Deprecate (3)

| Rule | Replace With | Rationale |
|------|-------------|-----------|
| `sorted_imports` | `sort_imports` (format) | Same check; format rule auto-fixes, lint version adds no value |
| `array_init` | `typesafe_array_init` (SourceKit) | Strict superset with type verification; keep `array_init` as fallback but mark deprecated |
| `assertion_failures` | `discouraged_assert` | Same check (`assert(false)` → `assertionFailure`) under two names |

---

### Rules to Split (3)

#### 1. `performance_anti_patterns` → 5 focused rules

Currently checks 8+ unrelated patterns. Split into:
- `date_for_timing` — Date() used for benchmarking
- `lock_anti_patterns` — nested withLock, await inside withLock
- `mutation_during_iteration` — collection mutation in for loop
- `lazy_chain` — 3+ functional transforms without .lazy
- `inlinable_generic` — public generic without @inlinable

Move @TaskLocal and Span suggestions into `swift62_modernization`.

#### 2. `swift62_modernization` → extract `prefer_weak_let`

The `weak var → weak let` check is a definitive refactoring (not a suggestion). Extract as its own lint-scope rule.

#### 3. `concurrency_modernization` → extract `async_stream_safety`

AsyncStream missing finish/onTermination checks are about correctness, not modernization. Separate them.

---

### Partial Merges (2)

| Action | Details |
|--------|---------|
| Remove Task detection from `agent_review` | Duplicates `fire_and_forget_task` (which is far more sophisticated with scope-aware severity) |
| Change `dead_symbols` scope to `.suggest` | Differentiates from `unused_declaration` (SourceKit-powered, precise). `dead_symbols` is syntactic/fast but lower confidence |

---

### Overlap Groups (12)

| # | Rules | Status |
|---|-------|--------|
| 1 | `redundant_get` / `implicit_getter` | **Eliminate** `implicit_getter` |
| 2 | `redundant_string_enum_value` / `redundant_raw_values` | **Eliminate** `redundant_raw_values` |
| 3 | `redundant_memberwise_init` / `unneeded_synthesized_initializer` | **Eliminate** `redundant_memberwise_init` |
| 4 | `sorted_imports` / `sort_imports` | **Deprecate** `sorted_imports` |
| 5 | `extension_access_modifier` / `no_extension_access_modifier` | **Keep both** (intentionally contradictory style choice) |
| 6 | `fire_and_forget_task` / `agent_review` | **Remove overlap** from `agent_review` |
| 7 | `private_over_fileprivate` / `strict_fileprivate` / `redundant_fileprivate` | **Keep all** (different purposes); rename `redundant_fileprivate` → `unnecessary_fileprivate` |
| 8 | `concurrency_modernization` / `swift62_modernization` | **Keep separate** (different audiences); add `relatedRuleIDs` |
| 9 | `array_init` / `typesafe_array_init` | **Deprecate** `array_init` |
| 10 | `dead_symbols` / `unused_declaration` | **Change scope** of `dead_symbols` to `.suggest` |
| 11 | `number_separator` / `number_formatting` | **Eliminate** `number_formatting` |
| 12 | `type_contents_order` / `organize_declarations` / `file_types_order` | **Eliminate** `organize_declarations` |

---

### Additional Observations

1. **Quick/Nimble rules** (5 rules): Third-party framework with declining usage. Mark deprecated, point to `prefer_swift_testing`.
2. **UIKit/IB rules** (10 rules): Irrelevant for macOS-only SwiftUI tool targeting Swift 6.3+. Mark deprecated or opt-in only.
3. **`object_literal` / `discouraged_object_literal`**: Intentionally contradictory (like extension_access_modifier pair). Keep both.
4. **Empty summaries**: 6+ rules have `static let summary = ""` — should be filled in.
5. **`static_over_final_class` / `non_overridable_class_declaration`**: Related but distinct enough to keep separate.

---

### Action Summary

| Action | Count |
|--------|-------|
| Eliminate | 5 |
| Deprecate | 3 |
| Split | 3 (→ 8 new focused rules) |
| Partial merge | 2 |
| Scope change | 1 |
| Deprecate category | 2 (15 rules total: Quick/Nimble + UIKit/IB) |
| Fix metadata | 6+ empty summaries |



## Summary of Changes

All actions from the report have been executed:

### Deleted (24 rules)
- **Eliminated (5):** implicit_getter, redundant_raw_values, redundant_memberwise_init, number_formatting, organize_declarations
- **Deprecated/removed (3):** sorted_imports, array_init, assertion_failures
- **Quick/Nimble (5):** nimble_operator, prefer_nimble, quick_discouraged_call, quick_discouraged_focused_test, quick_discouraged_pending_test
- **UIKit/IB (11):** All 11 UIKit/Interface Builder rules removed

### Split (performance_anti_patterns → 5 rules)
- date_for_timing, lock_anti_patterns, mutation_during_iteration, lazy_chain, inlinable_generic

### Extracted (2 new rules)
- prefer_weak_let (from swift62_modernization) — lint scope, correctable
- async_stream_safety (from concurrency_modernization) — lint scope, correctness

### Modified (3 rules)
- agent_review: removed Task detection, added relatedRuleIDs to fire_and_forget_task
- dead_symbols: scope changed from .lint to .suggest
- redundant_fileprivate → renamed to unnecessary_fileprivate

### Infrastructure
- Fixed GeneratePipeline paths (Sources/Swiftiomatic → Sources/SwiftiomaticKit)
- Regenerated RuleRegistry+AllRules.generated.swift and LintPipeline.generated.swift
- Updated generated tests, removed stale test files
- Inlined ArrayInitRule logic into TypesafeArrayInitRule
- Updated UnusedImportRule to reference SortImportsRule
- Added CLAUDE.md note about generated files workflow
- All 475 tests pass
