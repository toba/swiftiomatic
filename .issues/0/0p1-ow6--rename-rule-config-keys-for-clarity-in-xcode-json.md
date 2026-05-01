---
# 0p1-ow6
title: Rename rule config keys for clarity in Xcode JSON editor
status: in-progress
type: task
priority: normal
created_at: 2026-05-01T16:55:16Z
updated_at: 2026-05-01T17:41:07Z
sync:
    github:
        issue_number: "604"
        synced_at: "2026-05-01T18:16:41Z"
---

## Goal

Make configuration keys self-documenting at a glance. Xcode's JSON editor doesn't surface `description` from the schema, so the key itself has to carry the meaning.

## Principles

1. **Imperative verb leads.** Existing imperative prefixes are kept: `no…` (ban a construct or pattern), `prefer…`, `wrap…`, `collapse…`, `sort…`, `hoist…`, `reflow…`, `format…`, `require…`. New imperatives introduced for clarity: `drop…` (for autofix removals), `use…Not…` (when "prefer" alone is opaque), `flag…` (lint-only with no autofix and no obvious verb). `forbid…` is deliberately not used — `no…` already reads as imperative and is the established convention.
2. **Be specific about what's checked or rewritten.** A name like `preferAnyObject` doesn't say _on what_; `validateTestCases` doesn't say _what's validated_.
3. **≤ 40 characters.**
4. **Keep idiomatic Swift terms** (`flatMap`, `isEmpty`, `KeyPath`, `Self`, `@MainActor`) — those words already explain themselves.
5. **Type names mirror keys 1:1** by simple capitalization of the first character — no abbreviation, no divergence. The Swift type name is exactly the config key with its first character uppercased. E.g. `useAnyObjectOnDelegate` ↔ `UseAnyObjectOnDelegate`, `requireTestFnPrefixOrAttribute` ↔ `RequireTestFnPrefixOrAttribute`. Acronyms follow Swift API guidelines (uniformly cased — all lowercase when leading a camelCase key, all uppercase elsewhere): `flagForEachIDSelfInView` ↔ `FlagForEachIDSelfInView`, `dropRedundantSetterACL` ↔ `DropRedundantSetterACL`, `useURLMacroForURLLiterals` ↔ `UseURLMacroForURLLiterals`.

I left ~75% of rule names unchanged because they were already clear. Only changes are listed below — anything not mentioned stays as-is.

---

## `access`

| before | after |
|---|---|
| `aclConsistency` | `matchExtensionAccessToMembers` | 
| `extensionAccessLevel` | `hoistExtensionAccess` | 
| `privateStateVariables` | `makeStateVarsPrivate` |
| `fileScopedDeclarationPrivacy` | `useFilePrivateForFileLocal`|

## `blankLines`

`commentAsBlankLine` → `countCommentAsBlankLine`

## `closures`

| before | after | 
|---|---|
| `mutableCapture` | `flagMutableCapture` |
| `namedClosureParams` | `requireNamedClosureParams` | 
| `unhandledThrowingTask` | `flagUnhandledThrowingTask` |
| `onlyOneTrailingClosureArgument` | `noMultiTrailingClosures` |
| `ambiguousTrailingClosureOverload` | `flagAmbiguousTrailingClosure` |

## `comments`

| before | after |
|---|---|
| `expiringTodo` | `flagExpiringTodo` |
| `noLocalDocComments` | `noDocCommentsInsideFunctions` |
| `orphanedDocComment` | `flagOrphanedDocComment` |
| `tripleSlashDocComments` | `useTripleSlashForDocComments` | 
| `documentPublicDeclarations` | `requireDocsOnPublicDecls` |
| `docCommentsPrecedeModifiers` | `placeDocCommentsBeforeModifiers` |
| `requireParameterDocumentation` | `requireParameterDocs` |

## `conditions`

| before | after |
|---|---|
| `explicitNilCheck` | `useExplicitNilCheck` |
| `identicalOperands` | `flagIdenticalOperands` |
| `preferUnavailable` | `useUnavailableNotFatalError` |
| `preferIfElseChain` | `useIfElseNotSwitchOnBool` |
| `duplicateConditions` | `flagDuplicateConditions` |
| `preferCommaConditions` | `useCommaNotAndInConditions` |
| `preferConditionalExpression` | `useIfElseAsExpression`* | 

## `declarations`

| before | after |
|---|---|
| `accessorOrder` | `orderGetSetAccessors` |
| `modifierOrder` | `orderModifiers` |
| `emptyExtensions` | `removeEmptyExtensions` |
| `unusedSetterValue` | `flagUnusedSetterValue` |
| `preferMainAttribute` | `useMainAttributeNotMainFunc` |
| `preferOfficialCDecl` | `useAtCNotUnderscoreCDecl` |
| `initCoderUnavailable` | `markInitCoderUnavailable` |
| `oneDeclarationPerLine` | `splitMultipleDeclsPerLine` |
| `protocolAccessorOrder` | `orderProtocolAccessors` |
| `preferOfficialSpecialize` | `useAtSpecializeNotUnderscore` |
| `staticStructShouldBeEnum` | `convertStaticStructToEnum` |
| `preferSynthesizedInitializer` | `useSynthesizedInit` |
| `weakLetForUnreassignedWeakVar` | `useWeakLetForUnreassigned` |
| `preferSingleLinePropertyGetter` | `collapseSingleLineGetter` |

## `unsafety`

| before | after |
|---|---|
| `typedCatchError` | `useTypedCatchError` |
| `asyncStreamMissingTermination` | `requireAsyncStreamFinish` |
| `noMutationOfIteratedCollection` | `noMutationDuringIteration` |
| `warnRecursiveWithObservationTracking` | `flagRecursiveObservationTracking` |

## `memory`

| before | after |
|---|---|
| `weakDelegates` | `requireWeakDelegates` |
| `strongOutlets` | `useStrongOutlets` | 
| `preferWeakCapture` | `useWeakSelfInClosures` |
| `deinitObserverRemoval` | `requireObserverRemovalInDeinit` |
| `delegateProtocolRequiresAnyObject` | `requireAnyObjectOnDelegate` |
| `retainNotificationObserver` | `requireRetainOfNotificationObserver` |

## `generics`

| before | after |
|---|---|
| `opaqueGenericParameters` | `useSomeForGenericParameters` |
| `preferAngleBracketExtensions` | `useAngleBracketsOnExtensions` |

## `hoist`

Keep the group — group nesting aids organization. Rename the keys so each one mirrors its type under the strict-mirror rule (bare `try` / `await` are keywords and would otherwise diverge from `HoistTry` / `HoistAwait`):

| before | after |
|---|---|
| `hoist.try` | `hoist.hoistTry` |
| `hoist.await` | `hoist.hoistAwait` |
| `hoist.caseLet` | `hoist.hoistCaseLet` |
| `hoist.indirectEnum` | `hoist.hoistIndirectEnum` |

Type names (`HoistTry`, `HoistAwait`, `HoistCaseLet`, `HoistIndirectEnum`) are unchanged. The `hoist.hoistTry` path is mildly redundant on the page but consistent with how every other group works (the group is purely organizational; the key carries the full type name).

## `idioms`

Most `prefer…` names are already clear because they map to a well-known Swift idiom (`preferIsEmpty`, `preferKeyPath`, `preferFlatMap`, `preferContains`, `preferFirstWhere`, `preferLastWhere`, `preferAllSatisfy`, `preferCountWhere`, `preferIsDisjoint`, `preferReduceInto`, `preferMinMax`). Keep those.

| before | after |
|---|---|
| `preferFileID` | `useFileIDNotFile` |
| `avoidNoneName` | `noCaseNamedNone` |
| `noVoidTernary` | `noVoidTernary` |
| `preferSelfType` | `useSelfNotTypeName` |
| `warnForEachIDSelf` | `flagForEachIDSelfInView` |
| `noExplicitOwnership` | `noExplicitOwnershipModifiers` |
| `preferExplicitFalse` | `useExplicitFalseInGuards` |
| `leadingDotOperators` | `breakBeforeLeadingDot` |
| `warnSwapThenRemoveAll` | `flagSwapThenRemoveAll`* |
| `noDataDropPrefixInLoop` | `noDropFirstInForLoop`* |
| `preferEnvironmentEntry` | `useAtEntryNotEnvironmentKey` |
| `preferAssertionFailure` | `useAssertionFailureNotAssertFalse` |
| `preferLazyForLongChain` | `useLazyForLongChainOps` |
| `noFormatterInSwiftUIBody` | `noFormatterInViewBody` |
| `preferCompoundAssignment` | `useCompoundAssignment` |
| `noRetroactiveConformances` | `noRetroactiveConformances` |
| `noSortFilterInForEachData` | `noSortFilterInForEach` |
| `preferStaticOverClassFunc` | `useStaticNotClassFunc` |
| `replaceForEachWithForLoop` | `useForLoopNotForEach` |
| `preferTypedThrowsOverResult` | `useTypedThrowsNotResult` |
| `preferWhereClausesInForLoops` | `useWhereClauseInForLoop` |
| `preferContinuousClockOverDate` | `useContinuousClockNotDate` |
| `suggestOrderedSetForUniqueAppend` | `useOrderedSetForUniqueAppend` |
| `preferClosureNotificationObserver` | `useClosureNotificationObserver` |

## `lineBreaks`

| before | after |
|---|---|
| `beforeEachArgument` | `breakBeforeEachArgument` |
| `elseCatchOnNewLine` | `placeElseCatchOnNewLine` |
| `modifiersOnSameLine` | `keepModifiersOnSameLine` |
| `beforeGuardConditions` | `breakBeforeGuardConditions` |
| `beforeEachGenericRequirement` | `breakBeforeGenericRequirement` |
| `betweenDeclarationAttributes` | `breakBetweenDeclAttributes` |
| `aroundMultilineExpressionChainComponents` | `breakAroundMultilineChainParts` |

## `literals`

| before | after |
|---|---|
| `urlMacro` | `useURLMacroForURLLiterals` |
| `invisibleCharacters` | `flagInvisibleCharacters` |
| `noLiteralProtocolInit` | `noLiteralProtocolDirectInit`* |
| `emptyCollectionLiteral` | `flagEmptyCollectionLiteral` |
| `duplicateDictionaryKeys` | `flagDuplicateDictionaryKeys` |
| `preferEmptyCollectionForArrayArgs` | `useEmptyArrayLiteralForArgs` |
| `multiElementCollectionTrailingCommas` | `addTrailingCommaInMultiElementColl` |

## `naming`

| before | after |
|---|---|
| `uppercaseAcronyms` | `uppercaseAcronymsInIdentifiers` |
| `asciiIdentifiers` | `requireASCIIIdentifiers` |
| `camelCaseIdentifiers` | `requireCamelCaseIdentifiers` |

## `redundancies`

| before | after |
|---|---|
| `noSemicolons` | `dropSemicolons` |
| `redundantLet` | `dropRedundantLet` |
| `redundantInit` | `dropRedundantInitCall` |
| `redundantObjc` | `dropRedundantObjcAttribute` |
| `redundantSelf` | `dropRedundantSelf` |
| `redundantType` | `dropRedundantTypeAnnotation` |
| `redundantAsync` | `dropRedundantAsync` |
| `redundantBreak` | `dropRedundantBreak` |
| `redundantFinal` | `dropRedundantFinal` |
| `redundantReturn` | `dropRedundantReturn` |
| `redundantThrows` | `dropRedundantThrows` |
| `unusedArguments` | `dropUnusedArguments` |
| `noBacktickedSelf` | `dropBacktickedSelf` |
| `redundantClosure` | `dropRedundantClosureWrapper` |
| `redundantNilInit` | `dropRedundantNilInit` |
| `redundantPattern` | `dropRedundantCasePattern` |
| `redundantEscaping` | `dropRedundantEscaping` |
| `redundantSendable` | `dropRedundantSendable` |
| `redundantLetError` | `dropRedundantLetError` |
| `redundantOverride` | `dropRedundantOverride` |
| `redundantProperty` | `dropRedundantProperty` |
| `redundantEquatable` | `dropRedundantEquatable` |
| `redundantBackticks` | `dropRedundantBackticks` |
| `redundantRawValues` | `dropRedundantRawValues` |
| `redundantSetterACL` | `dropRedundantSetterACL` |
| `redundantEnumerated` | `dropRedundantEnumerated` |
| `redundantStaticSelf` | `dropRedundantStaticSelf` |
| `redundantViewBuilder` | `dropRedundantViewBuilder` |
| `redundantTypedThrows` | `dropRedundantTypedThrows` |
| `redundantAccessControl` | `dropRedundantAccessControl` |
| `unusedControlFlowLabel` | `dropUnusedControlFlowLabel` |
| `noLabelsInCasePatterns` | `dropLabelsInCasePatterns` |
| `redundantNilCoalescing` | `dropRedundantNilCoalescing` |
| `noFallThroughOnlyCases` | `dropFallthroughOnlyCases` |
| `redundantMainActorOnView` | `dropRedundantMainActorOnView` |
| `redundantOptionalBinding` | `dropRedundantOptionalBinding` |
| `redundantSwiftTestingSuite` | `dropRedundantSwiftTestingSuite` |

## `sort`

`sort.imports`, `sort.switchCases`, `sort.typeAliases`, `sort.declarations` — all clear given the group name.

## `spaces`

| before | after |
|---|---|
| `spacesAroundRangeFormationOperators` | `spaceAroundRangeOperators` |

## `testing`

| before | after |
|---|---|
| `finalTestCase` | `requireFinalOnXCTestCase` |
| **`validateTestCases`** | **`requireTestFnPrefixOrAttribute`** |
| `preferSwiftTesting` | `useSwiftTestingNotXCTest` |
| `testSuiteAccessControl` | `requireSuiteAccessControl`* |
| `swiftTestingTestCaseNames` | `enforceSwiftTestingNames`* |

## `types`

| before | after |
|---|---|
| **`preferAnyObject`** | **`useAnyObjectOnDelegate`** |
| `preferVoidReturn` | `useVoidNotEmptyTuple` |
| `preferFailableStringInit` | `useFailableStringInit` |
| `preferShorthandTypeNames` | `useShorthandTypeNames` |
| `preferNonOptionalDataInit` | `useNonOptionalDataInit` |
| `noVoidReturnOnFunctionSignature` | `dropVoidReturnFromSignature` |
| `noTypeRepetitionInStaticProperties` | `dropTypeInStaticProperty` |

## `wrap`

| before | after |
| `keepFunctionOutputTogether` | `keepReturnTypeWithSignature` |

## Group-names

Divide `idioms` into:

- `swiftui` — `noFormatterInSwiftUIBody`, `preferEnvironmentEntry`, `warnForEachIDSelf`, `preferClosureNotificationObserver`, `redundantMainActorOnView`
- `collections` — all the `prefer{First,Last,All,Count,Contains,IsEmpty,IsDisjoint,FlatMap,ReduceInto,MinMax}*` rules
- `controlFlow` — `replaceForEachWithForLoop`, `preferWhereClausesInForLoops`, `noSortFilterInForEachData`
- remainder stays as `idioms`

## Migration

Agent will update current project swiftiomatic.json as it works.
