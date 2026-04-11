---
# ypa-vrg
title: Single-line body format rule
status: completed
type: feature
priority: normal
created_at: 2026-04-11T19:01:44Z
updated_at: 2026-04-11T19:11:37Z
sync:
    github:
        issue_number: "188"
        synced_at: "2026-04-11T19:12:32Z"
---

Add a `single_line_body` format rule that condenses any braced block with a single statement onto one line when it fits within the print width.

## Requirements

- [x] Add `FormatAwareRule` protocol to bridge global `format.max_width` to rules
- [x] Update `RuleResolver.loadRules` with `formatDefaults` injection
- [x] Update call sites to pass format defaults
- [x] Create `SingleLineBodyOptions` with `max_width`
- [x] Create `SingleLineBodyRule` with Visitor + Rewriter
- [x] Run `swift run GeneratePipeline`
- [x] Create tests (20 passing)
- [x] Build and test (full suite — 474 pass, 3 pre-existing failures in unrelated rule)

## Constructs handled

- guard, if, for, while, do, defer, catch (`CodeBlockSyntax`)
- closures (`ClosureExprSyntax`)
- getter-only computed properties (`AccessorBlockSyntax`)
- willSet/didSet/get/set (`AccessorDeclSyntax`)

## Width calculation

Visual start column (tabs × indent width + spaces) + flattened single-line length ≤ max_width



## Summary of Changes

Added `single_line_body` opt-in format rule that condenses any single-statement braced block to one line when it fits within `format.max_width`.

**New files:**
- `SingleLineBodyRule.swift` — Rule + Visitor (4 node types) + Rewriter
- `SingleLineBodyOptions.swift` — `max_width` option
- `SingleLineBodyRuleTests.swift` — 20 tests

**Infrastructure:**
- `FormatAwareRule` protocol in `Rule.swift` — lets rules declare which global format keys they need
- `RuleResolver.loadRules` gains `formatDefaults` parameter — injects global format config into FormatAwareRule conformers
- Call sites (`SwiftiomaticCLI`, `FormatCommand`) pass `formatDefaults`
