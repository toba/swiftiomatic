---
# e8d-u08
title: Migrate Rules tests to Swift Testing
status: completed
type: task
priority: normal
created_at: 2026-04-14T02:55:02Z
updated_at: 2026-04-14T03:24:20Z
parent: rwb-wt3
blocked_by:
    - 9mz-jmv
sync:
    github:
        issue_number: "275"
        synced_at: "2026-04-14T03:28:23Z"
---

Convert 45 test files in `Tests/SwiftiomaticTests/Rules/` from XCTest to Swift Testing. Blocked by infrastructure rewrite (`9mz-jmv`).

## Files

44 files extend `LintOrFormatRuleTestCase`. After infrastructure converts the base class to free functions, each file needs:

- [ ] Replace `import XCTest` with `import Testing` (where present)
- [ ] Replace `final class FooTests: LintOrFormatRuleTestCase` with `@Suite struct FooTests`
- [ ] Replace `func testFoo()` with `@Test func foo()`
- [ ] Update `assertLint(...)` / `assertFormatting(...)` calls (now free functions, same signature minus file:/line:)

## Special Case: BeginDocumentationCommentWithOneLineSummaryTests

This file overrides `setUp()` to reset a static flag:
```swift
override func setUp() {
    BeginDocumentationCommentWithOneLineSummary._forcesFallbackModeForTesting = false
    super.setUp()
}
```

Use a `TestScoping` trait to reset the flag before each test:
```swift
struct ResetFallbackMode: TestTrait, TestScoping {
    func provideScope(
        for test: Test,
        testCase: Test.Case?,
        performing function: @concurrent @Sendable () async throws -> Void
    ) async throws {
        BeginDocumentationCommentWithOneLineSummary._forcesFallbackModeForTesting = false
        try await function()
    }
}

@Suite(.tags(.rules), ResetFallbackMode())
struct BeginDocumentationCommentWithOneLineSummaryTests { ... }
```

Alternatively, since only `testApproximationsOnMacOS()` sets the flag to `true`, and Swift Testing runs tests in isolation by default (no shared mutable state across tests), this may not need a trait at all — just set the flag at the start of that one test and it won't leak.

## Scope

Largely mechanical. All 44 subclasses follow identical patterns:
- Call `assertLint(RuleType.self, ...)` with emoji-marked source strings
- Call `assertFormatting(RuleType.self, input:expected:findings:...)` for correctable rules
- Use `FindingSpec(emoji, message:)` for expected diagnostics

### Full file list
AllPublicDeclarationsHaveDocumentationTests, AlwaysUseLiteralForEmptyCollectionInitTests, AlwaysUseLowerCamelCaseTests, AmbiguousTrailingClosureOverloadTests, AvoidRetroactiveConformancesTests, BeginDocumentationCommentWithOneLineSummaryTests, DoNotUseSemicolonsTests, DontRepeatTypeInStaticPropertiesTests, FileScopedDeclarationPrivacyTests, FullyIndirectEnumTests, GroupNumericLiteralsTests, IdentifiersMustBeASCIITests, ImportsXCTestVisitorTests, NeverForceUnwrapTests, NeverUseForceTryTests, NeverUseImplicitlyUnwrappedOptionalsTests, NoAccessLevelOnExtensionDeclarationTests, NoAssignmentInExpressionsTests, NoBlockCommentsTests, NoCasesWithOnlyFallthroughTests, NoEmptyLinesOpeningClosingBracesTests, NoEmptyTrailingClosureParenthesesTests, NoLabelsInCasePatternsTests, NoLeadingUnderscoresTests, NoParensAroundConditionsTests, NoPlaygroundLiteralsTests, NoVoidReturnOnFunctionSignatureTests, OmitReturnsTests, OneCasePerLineTests, OneVariableDeclarationPerLineTests, OnlyOneTrailingClosureArgumentTests, OrderedImportsTests, ReplaceForEachWithForLoopTests, ReturnVoidInsteadOfEmptyTupleTests, TypeNamesShouldBeCapitalizedTests, UseEarlyExitsTests, UseExplicitNilCheckInConditionsTests, UseLetInEveryBoundCaseVariableTests, UseShorthandTypeNamesTests, UseSingleLinePropertyGetterTests, UseSynthesizedInitializerTests, UseTripleSlashForDocumentationCommentsTests, UseWhereClausesInForLoopsTests, ValidateDocumentationCommentsTests
