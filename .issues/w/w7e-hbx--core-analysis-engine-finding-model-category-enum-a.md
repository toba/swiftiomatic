---
# w7e-hbx
title: 'Core analysis engine: Finding model, Category enum, Analyzer orchestrator'
status: completed
type: task
priority: normal
created_at: 2026-02-27T21:32:33Z
updated_at: 2026-02-27T21:49:41Z
parent: 52u-0w0
blocked_by:
    - v1g-3vl
sync:
    github:
        issue_number: "66"
        synced_at: "2026-03-01T01:01:43Z"
---

Build the core types that all checks depend on.

## Finding model (`Analysis/Finding.swift`)

- [ ] `Finding` struct with: category, severity (high/medium/low), file path, line, column, message, suggestion (optional), confidence (high/medium/low)
- [ ] Confidence replaces the grep scanner's markers: `high` = definitive (was unmarked), `medium` = likely true (was ⚡), `low` = needs human review (was 🔍)
- [ ] Conform to `Codable` for JSON output, `Comparable` for sorting by file:line

## Category enum (`Analysis/Category.swift`)

- [ ] 8 cases matching the swift-review skill categories:
  1. `anyElimination` — Generic consolidation & Any elimination
  2. `typedThrows` — Typed throws candidates
  3. `concurrencyModernization` — Structured concurrency / GCD modernization
  4. `swift62Modernization` — Swift 6.2 modernization
  5. `performanceAntiPatterns` — Performance anti-patterns
  6. `namingHeuristics` — Naming heuristics
  7. `observationPitfalls` — Observation framework pitfalls
  8. `agentReview` — Agent review candidates (cross-cutting, verified by other checks)
- [ ] Display names and § numbers for text output compatibility

## Analyzer orchestrator (`Analysis/Analyzer.swift`)

- [ ] Accept a list of file paths or a directory
- [ ] File discovery: recursively find `.swift` files, exclude `.build/`, `Pods/`, `DerivedData/`, `GRDB/`, `.git/`, `Carthage/`, `*.generated.swift`
- [ ] Parse each file with `SwiftParser.Parser.parse(source:)` — collect parse diagnostics as findings
- [ ] Run each registered check (SyntaxVisitor) over each parsed tree
- [ ] Collect findings from all checks into a sorted array
- [ ] Support two-pass mode: pass 1 runs declaration-collecting visitors, pass 2 runs reference-checking visitors (needed for dead symbols, duplication)
- [ ] Concurrent file parsing with TaskGroup for performance (files are independent)

## Summary of Changes
- Created Finding, Category, Severity, Confidence models
- Built BaseCheck class with SyntaxVisitor infrastructure
- Implemented FileDiscovery with exclusion patterns
- Built Analyzer orchestrator with concurrent parsing via TaskGroup
- All types are Codable and Sendable
