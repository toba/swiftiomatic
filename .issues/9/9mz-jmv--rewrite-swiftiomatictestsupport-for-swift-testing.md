---
# 9mz-jmv
title: Rewrite _SwiftiomaticTestSupport for Swift Testing
status: ready
type: task
priority: high
created_at: 2026-04-14T02:53:32Z
updated_at: 2026-04-14T02:53:32Z
parent: rwb-wt3
sync:
    github:
        issue_number: "278"
        synced_at: "2026-04-14T02:58:32Z"
---

Convert the `_SwiftiomaticTestSupport` module from XCTest base classes to Swift Testing-compatible free functions and traits. This is the **critical path blocker** — 116 test files depend on these helpers.

## Files to Convert

- [ ] `Sources/_SwiftiomaticTestSupport/DiagnosingTestCase.swift`
- [ ] `Sources/_SwiftiomaticTestSupport/FindingSpec.swift` (likely no changes)
- [ ] `Sources/_SwiftiomaticTestSupport/Parsing.swift` (likely no changes)
- [ ] `Sources/_SwiftiomaticTestSupport/MarkedText.swift` (likely no changes)
- [ ] `Sources/_SwiftiomaticTestSupport/Configuration+Testing.swift` (likely no changes)

## Conversion Plan

### DiagnosingTestCase → Free Functions

The `DiagnosingTestCase` class provides:
1. `makeContext(sourceFileSyntax:configuration:selection:findingConsumer:) -> Context`
2. `assertFindings(expected:markerLocations:emittedFindings:context:file:line:)`
3. `assertStringsEqualWithDiff(_:_:_:file:line:)`
4. Private helpers: `assertAndRemoveFinding`, `assertAndRemoveNote`

**Strategy**: Convert to module-level functions (not methods on a class). The `makeContext` helper accesses a global `ruleNameCache` — it doesn't need instance state.

```swift
// Before
open class DiagnosingTestCase: XCTestCase {
    func assertFindings(
        expected: [FindingSpec],
        markerLocations: [String: Int],
        emittedFindings: [Finding],
        context: Context,
        file: StaticString = #file,
        line: UInt = #line
    ) { ... }
}

// After
public func assertFindings(
    expected: [FindingSpec],
    markerLocations: [String: Int],
    emittedFindings: [Finding],
    context: Context,
    sourceLocation: SourceLocation = #_sourceLocation
) { ... }
```

### Key Assertion Replacements Inside Helpers

Inside these helpers, replace:
- `XCTFail("msg", file: file, line: line)` → `Issue.record("msg", sourceLocation: sourceLocation)`
- `XCTAssertEqual(a, b, file: file, line: line)` → `#expect(a == b, sourceLocation: sourceLocation)`
- Internal helper calls must thread `sourceLocation` parameter through

### PrettyPrintTestCase → Free Function

`PrettyPrintTestCase` provides `assertPrettyPrintEqual()` which:
- Parses input with MarkedText
- Runs PrettyPrinter
- Validates findings via `assertFindings()`
- Checks idempotency (re-runs formatter, verifies no changes)
- Compares with `assertStringsEqualWithDiff()`

Convert to a free function that calls the converted `assertFindings` and `assertStringsEqualWithDiff`:

```swift
public func assertPrettyPrintEqual(
    input: String,
    expected: String,
    linelength: Int,
    configuration: Configuration = .forTesting,
    whitespaceOnly: Bool = false,
    findings: [FindingSpec] = [],
    experimentalFeatures: Parser.ExperimentalFeatures = [],
    sourceLocation: SourceLocation = #_sourceLocation
) { ... }
```

### WhitespaceTestCase → Free Function

Similarly convert `assertWhitespaceLint()` to a free function.

### LintOrFormatRuleTestCase → Free Functions

Convert both:
- `assertLint<T: SyntaxLintRule>(_:_:findings:...)` → free function
- `assertFormatting(_:input:expected:findings:...)` → free function

These are generic functions — they work fine as free functions.

### WhitespaceLinterPerformanceTests (Special Case)

This file extends `DiagnosingTestCase` and calls `makeContext()`. After converting `makeContext` to a free function, this file only needs to update its call sites — it stays as an `XCTestCase` subclass (for `measure()`), just without the `DiagnosingTestCase` parent.

```swift
// Before
final class WhitespaceLinterPerformanceTests: DiagnosingTestCase {
    private func performWhitespaceLint(...) {
        let context = makeContext(...)
    }
}

// After
final class WhitespaceLinterPerformanceTests: XCTestCase {
    private func performWhitespaceLint(...) {
        let context = makeContext(...)  // now a free function
    }
}
```

## Import Changes

The module must export both `import Testing` and `import XCTest` (for the performance test). Use `@_exported import Testing` so consumers don't need to import it separately. The free functions should use Swift Testing assertions (`Issue.record`, `#expect`).

## Testing Strategy

After converting, run the full test suite to verify all 116 dependent test files still compile and pass before migrating them to `@Suite struct`.
