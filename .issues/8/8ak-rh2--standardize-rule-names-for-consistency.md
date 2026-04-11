---
# 8ak-rh2
title: Standardize rule names for consistency
status: completed
type: task
priority: normal
created_at: 2026-04-11T19:12:38Z
updated_at: 2026-04-11T20:14:52Z
sync:
    github:
        issue_number: "189"
        synced_at: "2026-04-11T20:31:36Z"
---

Rename ~25 rules for naming consistency across three merged rule sources.

## Changes

### 1. Synonym Standardization (redundant/unneeded/unnecessary/superfluous → redundant)
- [x] UnneededOverrideRule → RedundantOverrideRule
- [x] UnneededEscapingRule → RedundantEscapingRule
- [x] UnneededSynthesizedInitializerRule → RedundantSynthesizedInitializerRule
- [x] UnneededBreakInSwitchRule → RedundantBreakInSwitchRule
- [x] UnneededThrowsRule → RedundantThrowsRule (id: redundant_throws)
- [x] UnneededParenthesesInClosureArgumentRule → RedundantClosureArgumentParensRule
- [x] UnnecessaryFileprivateRule → RedundantFileprivateRule
- [x] SuperfluousElseRule → RedundantElseRule
- [x] SuperfluousDisableCommandRule → RedundantDisableCommandRule

### 2. Verb Tense
- [x] SortedEnumCasesRule → SortEnumCasesRule
- [x] SortedFirstLastRule → MinMaxOverSortedRule

### 3. Gerund vs Noun
- [x] ForceUnwrappingRule → ForceUnwrapRule

### 4. Prefer prefix
- [x] PreferSelfTypeOverTypeOfSelfRule → SelfTypeOverTypeOfSelfRule
- [x] PreferZeroOverExplicitInitRule → ZeroOverExplicitInitRule

### 5. Type/ID mismatch
- [x] EnumCaseAssociatedValuesLengthRule → EnumCaseAssociatedValuesCountRule

### 6. Long names
- [x] VerticalParameterAlignmentOnCallRule → CallParameterAlignmentRule
- [x] AnonymousArgumentInMultilineClosureRule → MultilineClosureAnonymousArgumentRule
- [x] EmptyParenthesesWithTrailingClosureRule → TrailingClosureEmptyParensRule
- [x] MultipleClosuresWithTrailingClosureRule → MultipleTrailingClosuresRule
- [x] RawValueForCamelCasedCodableEnumRule → CodableEnumRawValueRule
- [x] ContainsOverRangeNilComparisonRule → ContainsOverRangeCheckRule
- [x] NonOptionalStringDataConversionRule → StringDataConversionRule
- [x] BlankLinesBetweenChainedFunctionsRule → NoBlankLineInChainRule

### 7. Vague names
- [x] CaptureVariableRule → ImplicitSelfCaptureRule
- [x] ControlStatementRule → ControlStatementParensRule
- [x] LetVarWhitespaceRule → DeclarationWhitespaceRule
- [x] AttributesRule → AttributePlacementRule

### 8. Spacing vs Whitespace
- [x] ReturnArrowWhitespaceRule → ReturnArrowSpacingRule
- [x] FunctionNameWhitespaceRule → FunctionNameSpacingRule
- [x] OperatorUsageWhitespaceRule → OperatorUsageSpacingRule

### 9. Plural
- [x] BlankLinesAfterGuardStatementsRule → BlankLineAfterGuardRule

### Final
- [x] Run GeneratePipeline
- [x] Build succeeds
- [x] Tests pass (467 passed, 1 pre-existing failure in CollectionAlignmentRuleTests)


## Summary of Changes

Renamed 31 rules across 9 consistency categories. Replaced 11 hand-maintained generated test files with a single parameterized `RuleExampleTests` that iterates all registered rules automatically. Updated CLAUDE.md to reflect the new test approach.
