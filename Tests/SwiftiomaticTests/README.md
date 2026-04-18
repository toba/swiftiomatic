# SwiftiomaticTests

Comprehensive test suite validating all rules, the formatting engine, and core infrastructure.

## What It Does

Tests every rule, pretty-printer behavior, configuration edge case, and API contract in the project. Uses the `SwiftiomaticTestSupport` harness for marker-based finding assertions.

## Structure

| Directory | Purpose |
|---|---|
| `Rules/` | 150+ test files covering all lint and format rules with before/after source examples |
| `PrettyPrint/` | 80+ test files for the formatting engine (arrays, closures, functions, control flow, etc.) |
| `Core/` | Tests for documentation comments, rule masks, and syntax utilities |
| `API/` | Tests for configuration parsing and formatter/linter selection |

## Where It Fits

The primary test target. Run via `swift test` or Xcode's test navigator. Depends on `Swiftiomatic`, `SwiftiomaticTestSupport`, and `Generators` (to verify generated output stays consistent).
