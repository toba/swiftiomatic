---
# o2q-4qz
title: Add custom SuiteTrait for RuleRegistry initialization
status: ready
type: task
created_at: 2026-02-28T16:29:47Z
updated_at: 2026-02-28T16:29:47Z
parent: uac-wbq
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
