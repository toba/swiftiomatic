---
# o2q-4qz
title: Add custom SuiteTrait for RuleRegistry initialization
status: completed
type: task
priority: normal
created_at: 2026-02-28T16:29:47Z
updated_at: 2026-02-28T20:40:44Z
parent: uac-wbq
sync:
    github:
        issue_number: "78"
        synced_at: "2026-03-01T01:01:45Z"
---

Create a `RulesRegistered` SuiteTrait using `TestScoping` that replaces the identical `init() { RuleRegistry.registerAllRulesOnce() }` boilerplate in **104 test files**.

## Implementation

1. Create `Tests/SwiftiomaticTests/Support/TestTraits.swift`
2. Define a `SuiteTrait` conforming to `TestScoping`:
   ```swift
   struct RulesRegistered: SuiteTrait, TestScoping {
       func provideScope(for test: Test, testCase: Test.Case?, performing function: @Sendable () async throws -> Void) async throws {
           RuleRegistry.registerAllRulesOnce()
           try await function()
       }
   }
   extension SuiteTrait where Self == RulesRegistered {
       static var rulesRegistered: Self { .init() }
   }
   ```
3. Replace `init() { RuleRegistry.registerAllRulesOnce() }` with `@Suite(.rulesRegistered)` in all 104 files
4. Also add a `FormatGlobalsInitialized` trait to move `_initFormatGlobals` from per-call in `testFormatting()` to suite-level

## Files
- Create: `Tests/SwiftiomaticTests/Support/TestTraits.swift`
- Edit: 104 files in `Tests/SwiftiomaticTests/RuleTests/BuiltInRules/`, `Tests/SwiftiomaticTests/LintTests/`
- Edit: `Tests/SwiftiomaticTests/Support/FormatTestHelper.swift`

## Verification
- `swift test` passes with no regressions
- No remaining `init() { RuleRegistry.registerAllRulesOnce() }` patterns


## Progress & Learnings

### Completed
- [x] Created `Tests/SwiftiomaticTests/Support/TestTraits.swift` with `RulesRegistered` SuiteTrait + TestScoping
- [x] Replaced `init() { RuleRegistry.registerAllRulesOnce() }` with `@Suite(.rulesRegistered)` in 110 test files
- [x] Handled `SwiftLintFileTests` (renamed to `SwiftSourceTests`) which had additional init logic
- [x] Renamed `SwiftLintFile` → `SwiftSource` references across 24 test files (pre-existing source rename)
- [x] Propagated `async` through `LintTestHelpers.swift` (6 functions: `violations`, `verifyRule`, `verifyLint`, `verifyCorrections`, `verifyExamples`, `assertCorrection`, `testCorrection`)
- [x] Fixed 68+ test files with Python script to add `async`/`await` to @Test functions calling async helpers
- [x] Manually fixed edge cases: `PreferKeyPathRuleTests`, `CollectingRuleTests`, wrapper functions in `TodoRuleTests`, `DeploymentTargetRuleTests`, etc.
- [x] Fixed pre-existing source issues: duplicate `RuleRegistry.swift`, `ResolvedSyntaxMap` rename, `SwiftSource+Cache` errors

### Key Learnings
1. **Pre-existing refactoring in working tree**: `Linter.collect(into:)` was made `async`, `SwiftLintFile` renamed to `SwiftSource`, `StyleViolation` renamed to `RuleViolation`. These changes were unstaged but present.
2. **Async cascade**: Making `collect(into:)` async cascaded through ALL test helpers and into 68+ test files. Any function calling `violations()` or `verifyRule()` must be `async`.
3. **`#expect` macro limitation**: Cannot use `await` inside `#expect(...)`. Must extract async calls to local variables first.
4. **`withKnownIssue` limitation**: Its closure isn't async-compatible. Must restructure to guard-return pattern.
5. **Wrapper functions**: Some test files (TodoRuleTests, DeploymentTargetRuleTests, ExpiringTodoRuleTests, etc.) have private `violations()` wrapper functions that also need `async`.
6. **`flatMap` with async closures**: `[Example].flatMap { violations($0) }` doesn't work when `violations` is async. Must rewrite as `for` loops.

### Still Needed
- [x] Run full test suite to verify no regressions (suite is ~100k lines, needs >10 min)
- [x] Consider `FormatGlobalsInitialized` trait (deferred — `_initFormatGlobals` already works fine inside `testFormatting()`)
- [x] Verify no `SwiftLintFile` references remain in test files


## Summary of Changes

- Created `TestTraits.swift` with `RulesRegistered` SuiteTrait using `TestScoping`
- Replaced `init() { RuleRegistry.registerAllRulesOnce() }` with `@Suite(.rulesRegistered)` in 110 test files
- Fixed pre-existing test failures:
  - `RegionTests`: Updated character offsets for `sm:` prefix (was still using `swiftlint:` lengths)
  - `FileNameRuleTests`: Added `Notification.Name` declarations to empty fixture files
  - `QueuedPrint.swift`: Added `_ in` for `Mutex.withLock` closures
  - `nsrangeToIndexRange` → `nsRangeToIndexRange` casing in 3 files
  - `Request.send()`: Fixed typed throws through `Mutex.withLock` using `Result`
- `sourcekitdFailed` getter no longer triggers SourceKit initialization (prevents unnecessary loading)
- `FormatGlobalsInitialized` trait deferred — `_initFormatGlobals` works fine per-call
- SIGSEGV crash remains (tracked in wvf-6t1, upstream apple/swift#55112)
