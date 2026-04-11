---
# 8ak-rh2
title: Standardize rule names for consistency
status: in-progress
type: task
priority: normal
created_at: 2026-04-11T19:12:38Z
updated_at: 2026-04-11T19:12:38Z
sync:
    github:
        issue_number: "189"
        synced_at: "2026-04-11T19:12:48Z"
---

Rename ~25 rules for naming consistency across three merged rule sources.

## Changes

### 1. Synonym Standardization (redundant/unneeded/unnecessary/superfluous → redundant)
- [ ] UnneededOverrideRule → RedundantOverrideRule
- [ ] UnneededEscapingRule → RedundantEscapingRule
- [ ] UnneededSynthesizedInitializerRule → RedundantSynthesizedInitializerRule
- [ ] UnneededBreakInSwitchRule → RedundantBreakInSwitchRule
- [ ] UnneededThrowsRule → RedundantThrowsRule (id: redundant_throws)
- [ ] UnneededParenthesesInClosureArgumentRule → RedundantClosureArgumentParensRule
- [ ] UnnecessaryFileprivateRule → RedundantFileprivateRule
- [ ] SuperfluousElseRule → RedundantElseRule
- [ ] SuperfluousDisableCommandRule → RedundantDisableCommandRule

### 2. Verb Tense
- [ ] SortedEnumCasesRule → SortEnumCasesRule
- [ ] SortedFirstLastRule → MinMaxOverSortedRule

### 3. Gerund vs Noun
- [ ] ForceUnwrappingRule → ForceUnwrapRule

### 4. Prefer prefix
- [ ] PreferSelfTypeOverTypeOfSelfRule → SelfTypeOverTypeOfSelfRule
- [ ] PreferZeroOverExplicitInitRule → ZeroOverExplicitInitRule

### 5. Type/ID mismatch
- [ ] EnumCaseAssociatedValuesLengthRule → EnumCaseAssociatedValuesCountRule

### 6. Long names
- [ ] VerticalParameterAlignmentOnCallRule → CallParameterAlignmentRule
- [ ] AnonymousArgumentInMultilineClosureRule → MultilineClosureAnonymousArgumentRule
- [ ] EmptyParenthesesWithTrailingClosureRule → TrailingClosureEmptyParensRule
- [ ] MultipleClosuresWithTrailingClosureRule → MultipleTrailingClosuresRule
- [ ] RawValueForCamelCasedCodableEnumRule → CodableEnumRawValueRule
- [ ] ContainsOverRangeNilComparisonRule → ContainsOverRangeCheckRule
- [ ] NonOptionalStringDataConversionRule → StringDataConversionRule
- [ ] BlankLinesBetweenChainedFunctionsRule → NoBlankLineInChainRule

### 7. Vague names
- [ ] CaptureVariableRule → ImplicitSelfCaptureRule
- [ ] ControlStatementRule → ControlStatementParensRule
- [ ] LetVarWhitespaceRule → DeclarationWhitespaceRule
- [ ] AttributesRule → AttributePlacementRule

### 8. Spacing vs Whitespace
- [ ] ReturnArrowWhitespaceRule → ReturnArrowSpacingRule
- [ ] FunctionNameWhitespaceRule → FunctionNameSpacingRule
- [ ] OperatorUsageWhitespaceRule → OperatorUsageSpacingRule

### 9. Plural
- [ ] BlankLinesAfterGuardStatementsRule → BlankLineAfterGuardRule

### Final
- [ ] Run GeneratePipeline
- [ ] Build succeeds
- [ ] Tests pass
