# SwiftiomaticPerformanceTests

Performance benchmarks for resource-intensive components.

## What It Does

Uses XCTest `measure()` blocks to benchmark critical paths -- currently the whitespace linter running against large source files. Guards against performance regressions as rules and the formatting engine evolve.

## Where It Fits

A separate test target from `SwiftiomaticTests` so that performance benchmarks (which are slower and use `measure()`) don't slow down the main test suite. Depends on `Swiftiomatic` and `SwiftiomaticTestSupport`.
