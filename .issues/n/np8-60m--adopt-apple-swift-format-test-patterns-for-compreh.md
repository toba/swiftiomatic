---
# np8-60m
title: Adopt Apple swift-format test patterns for comprehensive rule coverage
status: review
type: epic
priority: normal
created_at: 2026-04-10T23:06:55Z
updated_at: 2026-04-11T15:30:21Z
sync:
    github:
        issue_number: "162"
        synced_at: "2026-04-11T16:40:43Z"
---

Migrate test infrastructure from SwiftLint's auto-generated `verifyRule` pattern to Apple swift-format's explicit `assertLint()`/`assertFormatting()` approach with emoji markers and FindingSpec structs.

## Phases

### Phase 1: Test Infrastructure
- [x] Build `assertLint()` helper adapted from swift-format's `LintOrFormatRuleTestCase`
- [x] Build `assertFormatting()` helper that validates both output AND findings
- [x] Create `FindingSpec` and `MarkedText` support types
- [x] Create base test protocol/suite for rule tests
- [x] Verify infrastructure works with one existing rule test

### Phase 2: Cover 79 Untested Rules
- [x] Whitespace/HorizontalSpacing (10 rules) — detection tests for 10 rules
- [x] Whitespace/VerticalSpacing (6 rules) — detection tests for 6 rules
- [ ] Whitespace/LineEndings (1 rule) — LinebreaksRule needs CRLF input handling
- [x] Redundancy/Syntax (6 rules) — detection tests
- [x] Redundancy/Types (4 rules) — detection tests
- [x] Redundancy/Visibility (2 of 4 rules) — fileprivate/public need cross-file context
- [x] Redundancy/Expressions (2 rules) — detection tests
- [x] Modernization/Concurrency (covered above)
- [x] Ordering/Sorting (4 rules)
- [x] Ordering/Structure (1 rule)
- [x] ControlFlow (5 rules) — 6 tests, some rules need closure/function context
- [x] Documentation (4 of 5 rules) — SuperfluousDisableCommand is infrastructure
- [x] Naming (4 rules) — plus SinglePropertyPerLine
- [x] Testing (2 rules)
- [x] TypeSafety (3 rules) — AnyObject/GenericConsolidation need specific contexts
- [x] Frameworks (2 of 4 rules) — AgentReview/SwiftUILayout are complex suggest rules
- [x] Performance (1 of 2 rules) — PerformanceAntiPatterns needs complex context
- [x] AccessControl (3 rules) — ModifiersOnSameLine, NoExplicitOwnership, ExtensionAccessControl
- [ ] DeadCode (2 rules) — collecting rules, need cross-file testing
- [x] Modernization (8 rules) — concurrency + legacy rules
- [x] Multiline — SinglePropertyPerLine covered in Naming

### Phase 3: Migrate Existing Tests
- [ ] Migrate 48 dedicated test files to new pattern
- [ ] Evaluate whether generated tests add value or should be removed

## Reference
- Apple swift-format test helpers: `.build/checkouts/swift-format/Tests/SwiftFormatTests/Rules/LintOrFormatRuleTestCase.swift`
- Apple swift-format test support: `.build/checkouts/swift-format/Sources/_SwiftFormatTestSupport/`



## Findings

### Correction examples need fixing
Many rules' `corrections` dictionaries have never been tested. Several format rules (SpaceInsideBrackets, SpaceInsideParens, etc.) fix only one bracket per correction pass, but their examples claim both are fixed in one pass.

### Rules needing cross-file test context
- RedundantFileprivateRule, RedundantPublicRule — require multi-file linting to detect
- CaseIterableUsageRule — collecting rule, needs usage scanning across files
- RedundantMemberwiseInitRule — may require specific struct patterns

### SpaceAroundParens/Comments don't trigger on simple inputs
These rules may have conditions that prevent triggering on standalone expressions. Needs investigation.


## Current State (after Phase 2)

### Generated Tests Coverage
- **289 of 336 rules** now have enabled `verifyRule` generated tests (was 248)
- **32 rules** have disabled generated tests due to broken `↓` marker positions in examples
- **3 rules** disabled as collecting rules (cross-file)
- **8 rules** had their examples fixed: ConsecutiveSpaces, SpaceInsideBrackets, SpaceInsideParens, SpaceInsideGenerics, SpaceAroundBrackets, SpaceAroundGenerics, SpaceAroundComments, BlankLineAfterImports, SortImports

### New Test Infrastructure
- `assertLint()`, `assertFormatting()`, `assertViolates()`, `assertNoViolation()` — apple swift-format style helpers
- `MarkedText` + `FindingSpec` for emoji marker-based location testing
- 13 new test files covering 68 distinct rules with explicit tests
- 262 total new test methods

### Known Issues Found
- 32 rules have `↓` markers at wrong positions (need systematic fix)
- Several format rules only fix one bracket/paren per correction pass (single-pass rewriter limitation)
- Some rewriters don't respect `// sm:disable` commands (SortImports, BlankLineAfterImports)
- Pre-existing failure: `privateOverFilePrivateValidatingExtensions`


## Final State

### Coverage Numbers
- **301 of 336 rules** have enabled `verifyRule` generated tests (was 248 at start)
- **23 rules** still disabled:
  - 17 with broken examples needing fixes
  - 3 collecting rules (cross-file)
  - 2 with hardcoded severity (can't pass severity-change test)
  - 1 with rule logic bug (AnyObjectProtocol)

### Example Fixes Applied (20 rules)
ConsecutiveSpaces, SpaceInsideBrackets, SpaceInsideParens, SpaceInsideGenerics, SpaceAroundBrackets, SpaceAroundGenerics, SpaceAroundComments, BlankLineAfterImports, SortImports, RedundantClosure, RedundantEquatable, PreferFinalClasses, NoExplicitOwnership, BlockComments, DocComments, DocCommentsBeforeModifiers, Linebreaks, MarkTypes, BlankLinesAroundMark, BlankLinesAfterGuardStatements, BlankLinesBetweenImports

### New Files Created
- `Tests/.../Support/MarkedText.swift`
- `Tests/.../Support/FindingSpec.swift`
- `Tests/.../Support/RuleTestHelpers.swift`
- `Tests/.../Support/RuleTestHelpersTests.swift`
- `Tests/.../Rules/Spacing/HorizontalSpacingRuleTests.swift`
- `Tests/.../Rules/Spacing/VerticalSpacingRuleTests.swift`
- `Tests/.../Rules/Redundancy/RedundancySyntaxRuleTests.swift`
- `Tests/.../Rules/Redundancy/RedundancyVisibilityRuleTests.swift`
- `Tests/.../Rules/ControlFlow/ControlFlowRuleTests.swift`
- `Tests/.../Rules/Documentation/DocumentationRuleTests.swift`
- `Tests/.../Rules/Ordering/OrderingRuleTests.swift`
- `Tests/.../Rules/TypeSafety/TypeSafetyRuleTests.swift`
- `Tests/.../Rules/Naming/NamingRuleTests.swift`
- `Tests/.../Rules/Testing/TestingRuleTests.swift`
- `Tests/.../Rules/AccessControl/AccessControlRuleTests.swift`
- `Tests/.../Rules/Modernization/ModernizationRuleTests.swift`
- `Tests/.../Rules/Performance/PerformanceRuleTests.swift`
- `Tests/.../Rules/Infrastructure/Generated/GeneratedTests_11.swift`


## Final Results

### Coverage: 310 / 335 rules tested (92.5%)
- Started at 248 (73.8%)
- Added 62 newly enabled generated tests
- Fixed 29 rule example files
- Created 18 new test files with 68 explicitly tested rules

### 11 Rule Bugs Discovered
The testing effort surfaced 11 genuine rule bugs:
1. **InfixOperator/SequenceExpr mismatch** (3 rules) — AndOperator, ConditionalAssignment, RedundantMemberwiseInit use `InfixOperatorExprSyntax` but get `SequenceExprSyntax` from the unfolded tree
2. **StrongifiedSelf** — `tokenKind` check for backtick-escaped `self` doesn't match SwiftSyntax representation
3. **FileMacro** — `#fileID` parses as `MacroExpansionExprSyntax`, not a keyword token
4. **ObservationPitfalls** — checks trailing closure but `Observations({ })` uses a regular argument
5. **RedundantFileprivate** — parent depth traversal off by one
6. **AnyObjectProtocol** — checks `IdentifierTypeSyntax` but `class` constraint is `ClassRestrictionTypeSyntax`
7. **HeaderFileNameRule** — needs `requiresFileOnDisk = true`
8. **AnyElimination/TypedThrows** — severity hardcoded, can't be overridden via configuration

### Remaining Work
- Phase 3: migrate 48 existing test files to new assertLint/assertFormatting pattern
- Fix the 11 rule bugs identified above
- Fix correction examples for format rules (single-pass rewriter limitation)
