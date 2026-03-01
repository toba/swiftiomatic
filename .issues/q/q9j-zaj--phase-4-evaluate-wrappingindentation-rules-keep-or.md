---
# q9j-zaj
title: 'Phase 4: Evaluate wrapping/indentation rules — keep or migrate'
status: ready
type: task
priority: normal
created_at: 2026-03-01T01:03:28Z
updated_at: 2026-03-01T01:03:28Z
parent: aku-gm2
blocked_by:
    - 6uk-rqg
sync:
    github:
        issue_number: "104"
        synced_at: "2026-03-01T01:41:12Z"
---

After phases 1–3, evaluate whether the remaining token-based wrapping and indentation rules should be ported to AST or kept as-is. These are the tokenizer's strongest use case — column-position-aware reformatting.

## Wrapping rules (13)

- [ ] wrap
- [ ] wrapArguments
- [ ] wrapAttributes
- [ ] wrapConditionalBodies
- [ ] wrapEnumCases
- [ ] wrapFunctionBodies
- [ ] wrapLoopBodies
- [ ] wrapMultilineConditionalAssignment
- [ ] wrapMultilineFunctionChains
- [ ] wrapMultilineStatementBraces
- [ ] wrapPropertyBodies
- [ ] wrapSingleLineComments
- [ ] wrapSwitchCases

## Indentation (1)

- [ ] indent

## Remaining token-based rules (20+)

These are rules not covered by phases 1–3 that need individual assessment:

- [ ] andOperator
- [ ] anyObjectProtocol
- [ ] applicationMain
- [ ] assertionFailures
- [ ] fileMacro
- [ ] genericExtensions
- [ ] initCoderUnavailable
- [ ] isEmpty
- [ ] noForceTryInTests
- [ ] noForceUnwrapInTests
- [ ] noGuardInTests
- [ ] opaqueGenericParameters
- [ ] privateStateVariables
- [ ] propertyTypes
- [ ] simplifyGenericConstraints
- [ ] strongOutlets
- [ ] strongifiedSelf
- [ ] swiftTestingTestCaseNames
- [ ] testSuiteAccessControl
- [ ] throwingTests
- [ ] trailingClosures
- [ ] typeSugar
- [ ] unusedArguments
- [ ] unusedPrivateDeclarations
- [ ] validateTestCases
- [ ] void
- [ ] urlMacro

## Decision criteria

- [ ] Measure: what % of the tokenizer + Formatter class is only used by wrapping/indent?
- [ ] Evaluate: does swift-syntax's trivia model support column-width-aware line breaking?
- [ ] Prototype: try porting `wrap` as a SyntaxRewriter to assess feasibility
- [ ] Decide: keep as specialized sub-engine, port, or remove

## Cleanup (after decision)

- [ ] Remove unused Tokenizer code if wrapping rules are ported
- [ ] Remove DiagnosticDeduplicator if all rules are AST-based
- [ ] Remove FormatRule, Formatter, FormatEngine if fully migrated
- [ ] Update CLI pipeline to single-engine execution
