# SwiftiomaticTestSupport

Shared test infrastructure for writing concise, location-aware rule tests.

## What It Does

Provides a test harness that lets rule tests embed `marker` characters in source code to assert exactly where findings should appear, eliminating fragile line/column math.

## Key Files

- **DiagnosingTestCase.swift** -- core test harness that parses, runs rules, and compares actual findings against expected locations.
- **FindingSpec.swift** -- declarative specifications for expected findings (message, category, notes).
- **MarkedText.swift** -- parser that extracts `^` markers from test source, mapping them to expected finding locations.
- **Configuration+Testing.swift** -- factory for test configurations with specific rules enabled/disabled.
- **Parsing.swift** -- helpers for parsing test source strings into syntax trees.

## Where It Fits

This is a non-test target (it lives in `Tests/` but is a regular `.target`, not a `.testTarget`) so that both `SwiftiomaticTests` and `SwiftiomaticPerformanceTests` can depend on it. It imports the `Swiftiomatic` library and re-exports test utilities.
