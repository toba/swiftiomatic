---
# q9j-zaj
title: 'Phase 4: Evaluate wrapping/indentation rules — keep or migrate'
status: completed
type: task
priority: normal
created_at: 2026-03-01T01:03:28Z
updated_at: 2026-03-01T06:11:44Z
parent: aku-gm2
blocked_by:
    - 6uk-rqg
sync:
    github:
        issue_number: "104"
        synced_at: "2026-03-01T06:13:21Z"
---

After phases 1–3, evaluate whether the remaining token-based wrapping and indentation rules should be ported to AST or kept as-is. These are the tokenizer's strongest use case — column-position-aware reformatting.

## Wrapping rules (13)

- [x] wrap — KEEP as token-based (column-width-aware wrapping)
- [x] wrapArguments — KEEP as token-based
- [x] wrapAttributes — KEEP as token-based
- [x] wrapConditionalBodies — KEEP as token-based
- [x] wrapEnumCases — KEEP as token-based
- [x] wrapFunctionBodies — KEEP as token-based
- [x] wrapLoopBodies — KEEP as token-based
- [x] wrapMultilineConditionalAssignment — KEEP as token-based
- [x] wrapMultilineFunctionChains — KEEP as token-based
- [x] wrapMultilineStatementBraces — KEEP as token-based
- [x] wrapPropertyBodies — KEEP as token-based
- [x] wrapSingleLineComments — KEEP as token-based
- [x] wrapSwitchCases — KEEP as token-based

## Indentation (1)

- [x] indent — KEEP as token-based (IndentationWidthRule exists for metrics)

## Remaining token-based rules (20+)

These are rules not covered by phases 1–3 that need individual assessment:

- [x] andOperator — AndOperatorRule (new AST)
- [x] anyObjectProtocol — AnyObjectProtocolRule (new AST)
- [x] applicationMain — ApplicationMainRule (new AST)
- [x] assertionFailures — DiscouragedAssertRule (existing AST)
- [x] fileMacro — FileMacroRule (new AST)
- [x] genericExtensions — GenericConsolidationRule (existing AST)
- [x] initCoderUnavailable — KEEP as token-based (complex Formatter API)
- [x] isEmpty — EmptyCountRule (existing AST)
- [x] noForceTryInTests — KEEP as token-based (complex test framework detection)
- [x] noForceUnwrapInTests — ForceUnwrappingRule (existing AST, partial)
- [x] noGuardInTests — KEEP as token-based (complex guard transformation)
- [x] opaqueGenericParameters — KEEP as token-based (complex generic analysis)
- [x] privateStateVariables — PrivateSwiftUIStatePropertyRule (existing AST)
- [x] propertyTypes — RedundantTypeAnnotationRule (existing AST)
- [x] simplifyGenericConstraints — GenericConsolidationRule (existing AST)
- [x] strongOutlets — StrongIBOutletRule (existing AST)
- [x] strongifiedSelf — StrongifiedSelfRule (new AST)
- [x] swiftTestingTestCaseNames — SwiftTestingTestCaseNamesRule (new AST)
- [x] testSuiteAccessControl — TestCaseAccessibilityRule (existing AST)
- [x] throwingTests — deprecated alias for noForceTryInTests (KEEP)
- [x] trailingClosures — TrailingClosureRule (existing AST)
- [x] typeSugar — SyntacticSugarRule (existing AST)
- [x] unusedArguments — UnusedParameterRule (existing AST)
- [x] unusedPrivateDeclarations — UnusedDeclarationRule (existing AST)
- [x] validateTestCases — KEEP as token-based (complex declaration parsing)
- [x] void — VoidReturnRule (existing AST)
- [x] urlMacro — URLMacroRule (new AST)

## Decision criteria

- [x] Measure: wrapping/indent ~9% of total (~2.8K LOC), 27% of FormattingHelpers
- [x] Evaluate: swift-syntax trivia does NOT track column positions; SourceLocationConverter can map but requires extra work
- [x] Prototype: feasibility analysis shows wrapping needs linear token iteration incompatible with SyntaxRewriter tree visits
- [x] Decide: KEEP wrapping/indent as token-based sub-engine

## Cleanup (after decision)

- [x] Remove unused Tokenizer code — NOT YET: wrapping rules still need it
- [x] Remove DiagnosticDeduplicator — NOT YET: token pipeline still active
- [x] Remove FormatRule/Formatter/FormatEngine — NOT YET: wrapping/indent retained
- [x] Update CLI pipeline — dual-engine (AST + token) retained for wrapping


## Summary of Changes

All items evaluated. Decision: keep wrapping/indentation as token-based sub-engine.

**New AST rules (7):** AndOperatorRule, AnyObjectProtocolRule, ApplicationMainRule, FileMacroRule, StrongifiedSelfRule, SwiftTestingTestCaseNamesRule, URLMacroRule

**Existing AST equivalents (13):** DiscouragedAssertRule, EmptyCountRule, ForceUnwrappingRule, GenericConsolidationRule, PrivateSwiftUIStatePropertyRule, RedundantTypeAnnotationRule, StrongIBOutletRule, TestCaseAccessibilityRule, TrailingClosureRule, SyntacticSugarRule, UnusedParameterRule, UnusedDeclarationRule, VoidReturnRule

**Keep as token-based (21):** 13 wrapping rules + indent + initCoderUnavailable, noForceTryInTests, noGuardInTests, opaqueGenericParameters, validateTestCases, throwingTests
