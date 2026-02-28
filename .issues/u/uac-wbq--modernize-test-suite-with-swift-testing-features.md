---
# uac-wbq
title: Modernize test suite with Swift Testing features
status: ready
type: epic
created_at: 2026-02-28T16:29:06Z
updated_at: 2026-02-28T16:29:06Z
---

Modernize the ~100k-line test suite to use advanced Swift Testing features. Already migrated from XCTest to basic `@Suite`/`@Test`, but no parameterization, custom traits, or TestScoping is used.

## Goals

- [ ] Custom traits to eliminate boilerplate init blocks (104 files)
- [ ] Parameterized tests where tests differ only by input data
- [ ] Split oversized test files (30+ files exceed 500 lines)
- [ ] Swift modernization: `#require`, modern URL APIs, eliminate force unwraps

## Scope Notes

These are largely **vendored test suites** (SwiftLint 0.63.2, SwiftFormat 0.59.1). Custom traits and parameterization are low-risk (additive). File splitting increases future merge burden — apply judiciously to the worst offenders.

## Current State

- **303 test files**, ~100k lines, ~5,961 `@Test` methods
- **0 parameterized tests** — all use individual `@Test func` methods
- **0 custom traits** — all setup in `init()` blocks
- **104 files** with identical `init() { RuleRegistry.registerAllRulesOnce() }` boilerplate
- **43 disabled tests** (15 from kmp-lex SuperfluousDisableCommand issue, rest from fixture mismatches)

### Largest Files
| File | Lines | @Test Count |
|------|-------|------------|
| IndentTests.swift | 6,142 | 357 |
| TokenizerTests.swift | 5,198 | 335 |
| OrganizeDeclarationsTests.swift | 4,605 | ~120 |
| RedundantSelfTests.swift | 4,322 | 249 |
| TrailingCommasTests.swift | 3,747 | 192 |
| ParsingHelpersTests.swift | 3,671 | ~100 |
| WrapArgumentsTests.swift | 3,366 | ~100 |
| + ~23 more files between 700–2,500 lines |
