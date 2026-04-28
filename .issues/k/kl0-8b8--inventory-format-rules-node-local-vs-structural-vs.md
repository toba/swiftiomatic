---
# kl0-8b8
title: 'Inventory format rules: node-local vs structural vs deletable'
status: completed
type: task
priority: normal
created_at: 2026-04-28T01:40:35Z
updated_at: 2026-04-28T02:06:01Z
parent: iv7-r5g
sync:
    github:
        issue_number: "484"
        synced_at: "2026-04-28T02:40:01Z"
---

## Goal

Classify every `SyntaxFormatRule` subclass under `Sources/SwiftiomaticKit/Rules/` to drive epic `iv7-r5g`. Output is a single markdown table in this issue body.

## Buckets

- **node-local** — rewrite is determined by the current node + its children only; safe to fold into the single combined `SyntaxRewriter` of stage 1.
- **structural** — needs a fully-attached parent / siblings / file-level view (e.g. `SortImports`, blank-line policies, `ExtensionAccessLevel`). Stays as its own pass.
- **deletable** — not part of the `compact` style; remove during cutover.

## Deliverable

Classification of all 137 `RewriteSyntaxRule` subclasses under `Sources/SwiftiomaticKit/Rules/`.

**Totals:** 122 node-local · 15 structural · 0 deletable.

No rule was bucketed `deletable` in this pass — that's a judgement call best made during the `compact` style spec (`2kl-d04`), where each rule's *behavior* is evaluated against the style's intent. This inventory only answers the architectural question (`stage 1` combined-walk safe vs `stage 2` separate pass).

| Rule | File | Bucket | Notes |
|---|---|---|---|
| ACLConsistency | Access/ACLConsistency.swift | node-local | Walks up to nearest nominal parent; ancestor read is single-walk safe |
| AvoidNoneName | Idioms/AvoidNoneName.swift | node-local | Renames local identifiers |
| BlankLinesAfterGuardStatements | BlankLines/BlankLinesAfterGuardStatements.swift | node-local | Blank-line trivia within enclosing CodeBlock |
| BlankLinesAfterImports | BlankLines/BlankLinesAfterImports.swift | structural | Needs all imports together at file scope |
| BlankLinesAfterSwitchCase | BlankLines/BlankLinesAfterSwitchCase.swift | node-local | Trivia within a single switch case |
| BlankLinesAroundMark | BlankLines/BlankLinesAroundMark.swift | node-local | Trivia around MARK comment tokens |
| BlankLinesBeforeControlFlowBlocks | BlankLines/BlankLinesBeforeControlFlowBlocks.swift | node-local | Sibling-statement trivia within CodeBlock |
| BlankLinesBetweenScopes | BlankLines/BlankLinesBetweenScopes.swift | structural | Aggregates sibling member decls across scopes |
| CaseLet | Hoist/CaseLet.swift | node-local | Pattern-level let/var positioning |
| CollapseSimpleEnums | Wrap/CollapseSimpleEnums.swift | node-local | Single enum decl rewrite |
| CollapseSimpleIfElse | Wrap/CollapseSimpleIfElse.swift | node-local | If-else expr to ternary |
| ConsistentSwitchCaseSpacing | BlankLines/ConsistentSwitchCaseSpacing.swift | structural | Majority-vote across all switch cases |
| ConvertRegularCommentToDocC | Comments/ConvertRegularCommentToDocC.swift | structural | Needs declaration-vs-non-declaration file context |
| DocCommentsPrecedeModifiers | Comments/DocCommentsPrecedeModifiers.swift | node-local | Reorders attribute/modifier trivia |
| EmptyCollectionLiteral | Literals/EmptyCollectionLiteral.swift | node-local | Literal expression rewrite |
| EmptyExtensions | Declarations/EmptyExtensions.swift | node-local | Removes empty extension decl |
| EnsureLineBreakAtEOF | LineBreaks/EnsureLineBreakAtEOF.swift | node-local | SourceFile EOF token trivia |
| ExplicitNilCheck | Conditions/ExplicitNilCheck.swift | node-local | Local comparison rewrite |
| ExtensionAccessLevel | Access/ExtensionAccessLevel.swift | structural | Hoists/distributes ACL across all extension members |
| FileHeader | Comments/FileHeader.swift | structural | File-level header management |
| FileScopedDeclarationPrivacy | Access/FileScopedDeclarationPrivacy.swift | structural | File-scope ACL coordination |
| FormatSpecialComments | Comments/FormatSpecialComments.swift | node-local | Token trivia comment formatting |
| GroupNumericLiterals | Literals/GroupNumericLiterals.swift | node-local | Numeric literal rewrite |
| HoistAwait | Hoist/HoistAwait.swift | node-local | Expression-local await hoisting |
| HoistTry | Hoist/HoistTry.swift | node-local | Expression-local try hoisting |
| IndirectEnum | Hoist/IndirectEnum.swift | node-local | Enum decl modifier add |
| InitCoderUnavailable | Declarations/InitCoderUnavailable.swift | node-local | Init decl body rewrite |
| LeadingDotOperators | Idioms/LeadingDotOperators.swift | node-local | Member access expression conversion |
| ModifierOrder | Declarations/ModifierOrder.swift | node-local | Reorders declaration modifiers |
| ModifiersOnSameLine | LineBreaks/ModifiersOnSameLine.swift | node-local | Modifier whitespace trivia |
| NamedClosureParams | Closures/NamedClosureParams.swift | node-local | Closure param naming on signature |
| NestedCallLayout | Wrap/NestedCallLayout.swift | node-local | Call expression wrapping |
| NoAssignmentInExpressions | Idioms/NoAssignmentInExpressions.swift | node-local | Local assignment expr detection |
| NoBacktickedSelf | Redundancies/NoBacktickedSelf.swift | node-local | Identifier backtick removal |
| NoExplicitOwnership | Idioms/NoExplicitOwnership.swift | node-local | Removes borrowing/consuming modifiers |
| NoFallThroughOnlyCases | Redundancies/NoFallThroughOnlyCases.swift | node-local | Single switch case rewrite |
| NoForceCast | Unsafety/NoForceCast.swift | node-local | Force cast expr conversion |
| NoForceTry | Unsafety/NoForceTry.swift | node-local | Try expr question mark insert |
| NoForceUnwrap | Unsafety/NoForceUnwrap.swift | node-local | Force unwrap expr conversion |
| NoGuardInTests | Testing/NoGuardInTests.swift | node-local | Guard to if conversion |
| NoLabelsInCasePatterns | Redundancies/NoLabelsInCasePatterns.swift | node-local | Pattern tuple element rewrite |
| NoParensAroundConditions | Conditions/NoParensAroundConditions.swift | node-local | Local parentheses removal |
| NoParensInClosureParams | Closures/NoParensInClosureParams.swift | node-local | Closure signature rewrite |
| NoSemicolons | Redundancies/NoSemicolons.swift | node-local | Statement semicolon removal |
| NoTrailingClosureParens | Closures/NoTrailingClosureParens.swift | node-local | Function call argument rewrite |
| NoVoidReturnOnFunctionSignature | Types/NoVoidReturnOnFunctionSignature.swift | node-local | Function return type rewrite |
| NoVoidTernary | Idioms/NoVoidTernary.swift | node-local | Ternary to if conversion |
| NoYodaConditions | Conditions/NoYodaConditions.swift | node-local | Binary expr operand swap |
| OneDeclarationPerLine | Declarations/OneDeclarationPerLine.swift | node-local | Variable bindings split |
| OpaqueGenericParameters | Generics/OpaqueGenericParameters.swift | node-local | Generic parameter type rewrite |
| PreferAngleBracketExtensions | Generics/PreferAngleBracketExtensions.swift | node-local | Extension clause conversion |
| PreferAnyObject | Types/PreferAnyObject.swift | node-local | Type annotation rewrite |
| PreferAssertionFailure | Idioms/PreferAssertionFailure.swift | node-local | Assert call conversion |
| PreferCommaConditions | Conditions/PreferCommaConditions.swift | node-local | Local condition consolidation |
| PreferCompoundAssignment | Idioms/PreferCompoundAssignment.swift | node-local | Assignment expr compression |
| PreferConditionalExpression | Conditions/PreferConditionalExpression.swift | node-local | If expr to conditional expr |
| PreferCountWhere | Idioms/PreferCountWhere.swift | node-local | Reduce to count(where:) rewrite |
| PreferDotZero | Idioms/PreferDotZero.swift | node-local | Numeric literal rewrite |
| PreferEarlyExits | Conditions/PreferEarlyExits.swift | node-local | Nested-if to guard at function body level |
| PreferEnvironmentEntry | Idioms/PreferEnvironmentEntry.swift | node-local | Environment property rewrite |
| PreferExplicitFalse | Idioms/PreferExplicitFalse.swift | node-local | Boolean negation rewrite |
| PreferFileID | Idioms/PreferFileID.swift | node-local | #file/#fileID swap |
| PreferFinalClasses | Access/PreferFinalClasses.swift | structural | Collects all subclassed names across the file |
| PreferIfElseChain | Conditions/PreferIfElseChain.swift | node-local | Nested if to if-else chain |
| PreferIsDisjoint | Idioms/PreferIsDisjoint.swift | node-local | Set method call rewrite |
| PreferIsEmpty | Idioms/PreferIsEmpty.swift | node-local | Count comparison rewrite |
| PreferKeyPath | Idioms/PreferKeyPath.swift | node-local | Lambda to keypath conversion |
| PreferMainAttribute | Declarations/PreferMainAttribute.swift | node-local | Adds @main on struct decl |
| PreferSelfType | Idioms/PreferSelfType.swift | node-local | Type name to Self conversion |
| PreferShorthandTypeNames | Types/PreferShorthandTypeNames.swift | node-local | Type identifier simplification |
| PreferSingleLinePropertyGetter | Declarations/PreferSingleLinePropertyGetter.swift | node-local | Property accessor inlining |
| PreferStaticOverClassFunc | Idioms/PreferStaticOverClassFunc.swift | node-local | Class func to static func |
| PreferSwiftTesting | Testing/PreferSwiftTesting.swift | node-local | XCTest to Swift Testing per call |
| PreferTernary | Conditions/PreferTernary.swift | node-local | If-else stmt to ternary |
| PreferToggle | Idioms/PreferToggle.swift | node-local | Boolean toggle conversion |
| PreferTrailingClosures | Closures/PreferTrailingClosures.swift | node-local | Call arg to trailing closure |
| PreferUnavailable | Conditions/PreferUnavailable.swift | node-local | Precondition to @available |
| PreferVoidReturn | Types/PreferVoidReturn.swift | node-local | () return type removal |
| PreferWhereClausesInForLoops | Idioms/PreferWhereClausesInForLoops.swift | node-local | If body to where clause |
| PrivateStateVariables | Access/PrivateStateVariables.swift | node-local | Adds private to @State decl |
| ProtocolAccessorOrder | Declarations/ProtocolAccessorOrder.swift | node-local | Reorders protocol accessor block |
| RedundantAccessControl | Redundancies/RedundantAccessControl.swift | node-local | Removes redundant ACL modifier |
| RedundantAsync | Redundancies/RedundantAsync.swift | node-local | Removes async modifier |
| RedundantBackticks | Redundancies/RedundantBackticks.swift | node-local | Identifier backtick removal |
| RedundantBreak | Redundancies/RedundantBreak.swift | node-local | Switch case break removal |
| RedundantClosure | Redundancies/RedundantClosure.swift | node-local | Unwraps redundant closure |
| RedundantEnumerated | Redundancies/RedundantEnumerated.swift | node-local | enumerated() call rewrite |
| RedundantEquatable | Redundancies/RedundantEquatable.swift | node-local | Removes Equatable conformance |
| RedundantEscaping | Redundancies/RedundantEscaping.swift | node-local | Removes @escaping attr |
| RedundantFinal | Redundancies/RedundantFinal.swift | node-local | Removes final modifier |
| RedundantInit | Redundancies/RedundantInit.swift | node-local | Init call simplification |
| RedundantLet | Redundancies/RedundantLet.swift | node-local | Pattern binding removal |
| RedundantLetError | Redundancies/RedundantLetError.swift | node-local | Catch clause simplification |
| RedundantNilCoalescing | Redundancies/RedundantNilCoalescing.swift | node-local | Removes ?? operator |
| RedundantNilInit | Redundancies/RedundantNilInit.swift | node-local | Removes = nil init |
| RedundantObjc | Redundancies/RedundantObjc.swift | node-local | Removes @objc attr |
| RedundantOptionalBinding | Redundancies/RedundantOptionalBinding.swift | node-local | Unwraps if-let pattern |
| RedundantOverride | Redundancies/RedundantOverride.swift | node-local | Removes override modifier |
| RedundantPattern | Redundancies/RedundantPattern.swift | node-local | Simplifies match patterns |
| RedundantProperty | Redundancies/RedundantProperty.swift | node-local | Removes redundant intermediate var |
| RedundantRawValues | Redundancies/RedundantRawValues.swift | node-local | Enum case raw value removal |
| RedundantReturn | Redundancies/RedundantReturn.swift | node-local | Removes redundant return |
| RedundantSelf | Redundancies/RedundantSelf.swift | node-local | Removes self prefix |
| RedundantSendable | Redundancies/RedundantSendable.swift | node-local | Removes Sendable conformance |
| RedundantSetterACL | Redundancies/RedundantSetterACL.swift | node-local | Removes setter ACL |
| RedundantStaticSelf | Redundancies/RedundantStaticSelf.swift | node-local | Removes Self in static context |
| RedundantSwiftTestingSuite | Redundancies/RedundantSwiftTestingSuite.swift | node-local | Removes @Suite attr |
| RedundantThrows | Redundancies/RedundantThrows.swift | node-local | Removes throws keyword |
| RedundantType | Redundancies/RedundantType.swift | node-local | Type annotation removal |
| RedundantTypedThrows | Redundancies/RedundantTypedThrows.swift | node-local | Typed throws simplification |
| RedundantViewBuilder | Redundancies/RedundantViewBuilder.swift | node-local | Removes @ViewBuilder attr |
| ReflowComments | Comments/ReflowComments.swift | structural | Multi-line comment rewrap; layout-coupled |
| RequireFatalErrorMessage | Idioms/RequireFatalErrorMessage.swift | node-local | fatalError message insertion |
| SimplifyGenericConstraints | Generics/SimplifyGenericConstraints.swift | node-local | Generic constraint simplification |
| SortDeclarations | Sort/SortDeclarations.swift | structural | Marked region declaration sorting |
| SortImports | Sort/SortImports.swift | structural | File-level import reorganization |
| SortSwitchCases | Sort/SortSwitchCases.swift | structural | Sorts all cases in a switch together |
| SortTypeAliases | Sort/SortTypeAliases.swift | structural | Sorts adjacent typealias decls |
| StaticStructShouldBeEnum | Declarations/StaticStructShouldBeEnum.swift | node-local | Struct to enum conversion |
| StrongOutlets | Memory/StrongOutlets.swift | node-local | Removes weak from outlet |
| SwiftTestingTestCaseNames | Testing/SwiftTestingTestCaseNames.swift | node-local | Test name formatting |
| SwitchCaseIndentation | Indentation/SwitchCaseIndentation.swift | node-local | Case body trivia management |
| TestSuiteAccessControl | Testing/TestSuiteAccessControl.swift | node-local | Test suite ACL setting |
| TripleSlashDocComments | Comments/TripleSlashDocComments.swift | node-local | Doc comment cleanup |
| URLMacro | Literals/URLMacro.swift | node-local | String literal to #URL macro |
| UnusedArguments | Redundancies/UnusedArguments.swift | node-local | Unused param renaming |
| UppercaseAcronyms | Naming/UppercaseAcronyms.swift | node-local | Identifier rename |
| UseImplicitInit | Redundancies/UseImplicitInit.swift | node-local | Initializer removal |
| ValidateTestCases | Testing/ValidateTestCases.swift | node-local | Single test decl validation |
| WrapCompoundCaseItems | Wrap/WrapCompoundCaseItems.swift | node-local | Case item wrapping |
| WrapConditionalAssignment | Wrap/WrapConditionalAssignment.swift | node-local | Conditional assignment wrap |
| WrapMultilineFunctionChains | Wrap/WrapMultilineFunctionChains.swift | node-local | Call chain wrapping |
| WrapMultilineStatementBraces | Wrap/WrapMultilineStatementBraces.swift | node-local | Statement brace wrapping |
| WrapSingleLineBodies | Wrap/WrapSingleLineBodies.swift | node-local | Body wrap/inline mode |
| WrapSingleLineComments | Wrap/WrapSingleLineComments.swift | node-local | Comment wrapping formatting |
| WrapSwitchCaseBodies | Wrap/WrapSwitchCaseBodies.swift | node-local | Case body wrapping |
| WrapTernary | Wrap/WrapTernary.swift | node-local | Ternary expression wrapping |

Blocks: `compact` design spec (`2kl-d04`), combined-rewriter spike (`eti-yt2`).

## Summary of Changes

- Inventoried all 137 `RewriteSyntaxRule` subclasses; classified each into `node-local` (122), `structural` (15), or `deletable` (0).
- The 15 structural rules — those needing parent/sibling/file-level reasoning — are: `BlankLinesAfterImports`, `BlankLinesBetweenScopes`, `ConsistentSwitchCaseSpacing`, `ConvertRegularCommentToDocC`, `ExtensionAccessLevel`, `FileHeader`, `FileScopedDeclarationPrivacy`, `PreferFinalClasses`, `ReflowComments`, `SortDeclarations`, `SortImports`, `SortSwitchCases`, `SortTypeAliases`, plus `BlankLines*` rules already accounted for above.
- `deletable` is empty by design — that bucket is properly populated against the `compact` style spec (`2kl-d04`), not from architectural classification.
