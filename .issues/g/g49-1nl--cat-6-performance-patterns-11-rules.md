---
# g49-1nl
title: 'Cat 6: Performance Patterns (11 rules)'
status: ready
type: feature
priority: normal
created_at: 2026-04-15T00:27:58Z
updated_at: 2026-04-15T00:27:58Z
parent: qlt-10c
sync:
    github:
        issue_number: "316"
        synced_at: "2026-04-15T00:34:46Z"
---

Collection algorithm optimizations. All lint-only (suggest better APIs).

| SwiftLint Rule | Swiftiomatic Name | Scope | Description |
|---|---|---|---|
| `first_where` | PreferFirstWhere | `.lint` | `.first(where:)` over `.filter { }.first` |
| `last_where` | PreferLastWhere | `.lint` | `.last(where:)` over `.filter { }.last` |
| `contains_over_filter_count` | PreferContains | `.lint` | `contains` over `filter.count == 0` |
| `contains_over_filter_is_empty` | PreferContains | `.lint` | `contains` over `filter.isEmpty` |
| `contains_over_first_not_nil` | PreferContains | `.lint` | `contains` over `first(where:) != nil` |
| `contains_over_range_nil_comparison` | PreferContains | `.lint` | `contains` over `range(of:) != nil` |
| `flatmap_over_map_reduce` | PreferFlatMap | `.lint` | `flatMap` over `map + reduce([], +)` |
| `reduce_boolean` | PreferAllSatisfy | `.lint` | `allSatisfy`/`contains` over `reduce(true/false)` |
| `reduce_into` | PreferReduceInto | `.lint` | `reduce(into:)` for copy-on-write types |
| `sorted_first_last` | PreferMinMax | `.lint` | `min()`/`max()` over `sorted().first/last` |
| `final_test_case` | FinalTestCase | `.lint` | XCTestCase subclasses should be final |

Note: The 4 `contains_over_*` rules could share a single `PreferContains` rule with multiple detection patterns.
