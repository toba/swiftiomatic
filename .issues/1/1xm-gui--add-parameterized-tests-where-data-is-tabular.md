---
# 1xm-gui
title: Add parameterized tests where data is tabular
status: completed
type: task
priority: normal
created_at: 2026-02-28T16:29:48Z
updated_at: 2026-02-28T21:09:13Z
parent: uac-wbq
---

Identify and convert test methods that differ only by input data into parameterized tests using `@Test(arguments:)`.

## Candidates

**Good targets** (tests that are genuinely tabular — same logic, different data):
- Tests with simple input-only calls (no-op formatting) that could share a single parameterized method
- Configuration parsing tests with multiple input formats → same expected result
- Version parsing/comparison tests
- Any test suite where 5+ methods have identical structure differing only in string literals

**Not good targets** (leave as-is):
- Format rule tests where each test has unique multi-line fixtures with distinct formatting edge cases — these benefit from descriptive test names
- Tests that vary options/exclude lists alongside input (too many dimensions)

## Approach

1. Audit the 30+ largest test files for parameterization opportunities
2. For each candidate, create a `CustomStringConvertible` struct (for test name display) or use tuples
3. Group related test data into static arrays
4. Replace N individual `@Test func` methods with `@Test(arguments: cases) func`

## Verification
- `swift test` passes with no regressions
- Test count remains the same (parameterized tests expand at runtime)
- Each parameterized test case has a descriptive label



## Summary of Changes

Added `FormatCase` struct to `FormatTestHelper.swift` for parameterized test support. Converted 4 test files:

| File | Before | After | Parameterized |
|------|--------|-------|---------------|
| YodaConditionsTests | 50 methods | 3 methods | 48 cases |
| SpaceAroundParensTests | 65 methods | 15 methods | 51 cases |
| SpaceAroundOperatorsTests | 122 methods | 51 methods | 72 cases |
| RedundantParensTests | 178 methods | 31 methods | 124 cases |
| **Total** | **415 methods** | **100 methods** | **295 cases** |

Tests with `exclude:` or `options:` parameters kept as individual `@Test func` methods since `FormatRule` is not `Sendable`.
