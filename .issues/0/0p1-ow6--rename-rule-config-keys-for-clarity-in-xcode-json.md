---
# 0p1-ow6
title: Rename rule config keys for clarity in Xcode JSON editor
status: draft
type: task
priority: normal
created_at: 2026-05-01T16:55:16Z
updated_at: 2026-05-01T16:55:16Z
sync:
    github:
        issue_number: "603"
        synced_at: "2026-05-01T17:11:51Z"
---

## Goal

Make configuration keys self-documenting at a glance. Xcode's JSON editor doesn't surface `description` from the schema, so the key itself has to carry the meaning.

## Principles

1. **Imperative verb leads.** Existing imperative prefixes are kept: `no…`, `prefer…`, `wrap…`, `collapse…`, `sort…`, `hoist…`, `reflow…`, `format…`, `require…`. New imperatives introduced for clarity: `drop…` (for autofix removals), `use…Not…` (when "prefer" alone is opaque), `flag…` (lint-only with no autofix and no obvious verb).
2. **Be specific about what's checked or rewritten.** A name like `preferAnyObject` doesn't say _on what_; `validateTestCases` doesn't say _what's validated_.
3. **≤ 40 characters.**
4. **Keep idiomatic Swift terms** (`flatMap`, `isEmpty`, `KeyPath`, `Self`, `@MainActor`) — those words already explain themselves.
5. **Type names mirror keys 1:1** (PascalCase ↔ camelCase). E.g. `useAnyObjectOnDelegate` → `UseAnyObjectOnDelegate`.

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

`commentAsBlankLine` → `treatCommentAsBlankLine`

## `closures`

| before | after | 
|---|---|
| `mutableCapture` | `flagMutableCapture` |
| `namedClosureParams` | `requireNamedClosureParams` | 
| `unhandledThrowingTask` | `flagUnhandledThrowingTask` |
| `onlyOneTrailingClosureArgument` | `forbidMultiTrailingClosures` |
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
| `identicalOperands` | `flagIdenticalOperands`* |
| `preferUnavailable` | `useUnavailableNotFatalError` |
| `preferIfElseChain` | `useIfElseNotSwitchOnBool` |
| `duplicateConditions` | `flagDuplicateConditions`* |
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
| `preferOfficialSpecialize` | `useAtSpecializeNotUnderscore`* |
| `staticStructShouldBeEnum` | `convertStaticStructToEnum` |
| `preferSynthesizedInitializer` | `useSynthesizedInit` |
| `weakLetForUnreassignedWeakVar` | `useWeakLetForUnreassigned` |
| `preferSingleLinePropertyGetter` | `collapseSingleLineGetter` |

## `unsafety`

| before | after | reason |
|---|---|---|
| `typedCatchError` | `useTypedCatchError` | imperative |
| `asyncStreamMissingTermination` | `requireAsyncStreamFinish` | shorter, imperative |
| `noMutationOfIteratedCollection` | `noMutationDuringIteration` | shorter |
| `warnRecursiveWithObservationTracking` | `flagRecursiveObservationTracking` | shorter |

## `memory`

| before | after | reason |
|---|---|---|
| `weakDelegates` | `requireWeakDelegates` | imperative |
| `strongOutlets` | `useStrongOutlets` | clarifies (rewrites `weak` IBOutlets to strong) |
| `preferWeakCapture` | `useWeakSelfInClosures` | clarifies trigger |
| `deinitObserverRemoval` | `requireObserverRemovalInDeinit` | clarifies |
| `delegateProtocolRequiresAnyObject` | `requireAnyObjectOnDelegate` | shorter |
| `retainNotificationObserver` | `requireRetainOfNotificationObserver` | clarifies |

## `generics`

| before | after | reason |
|---|---|---|
| `opaqueGenericParameters` | `useSomeForGenericParameters` | clarifies (uses `some P` over `<T: P>`) |
| `preferAngleBracketExtensions` | `useAngleBracketsOnExtensions` | imperative |

## `hoist`

`hoist.try`, `hoist.await`, `hoist.caseLet`, `hoist.indirectEnum` — all clear in context.

## `idioms`

Most `prefer…` names are already clear because they map to a well-known Swift idiom (`preferIsEmpty`, `preferKeyPath`, `preferFlatMap`, `preferContains`, `preferFirstWhere`, `preferLastWhere`, `preferAllSatisfy`, `preferCountWhere`, `preferIsDisjoint`, `preferReduceInto`, `preferMinMax`). Keep those.

| before | after | reason |
|---|---|---|
| `preferFileID` | `useFileIDNotFile` | clarifies replacement |
| `avoidNoneName` | `forbidNoneAsCaseName` | clarifies |
| `noVoidTernary` | `forbidVoidTernary` | imperative |
| `preferSelfType` | `useSelfNotTypeName` | clarifies |
| `warnForEachIDSelf` | `flagForEachIdSelf` | imperative |
| `noExplicitOwnership` | `forbidExplicitOwnershipModifiers` | clarifies |
| `preferExplicitFalse` | `useExplicitFalseInGuards` | clarifies |
| `leadingDotOperators` | `breakBeforeLeadingDot` | clarifies (this is a wrap rule) |
| `warnSwapThenRemoveAll` | `flagSwapThenRemoveAll` | imperative |
| `noDataDropPrefixInLoop` | `noDropFirstInForLoop` | clarifies (Data prefix is misleading) |
| `preferEnvironmentEntry` | `useAtEntryNotEnvironmentKey` | clarifies |
| `preferAssertionFailure` | `useAssertionFailureNotAssertFalse` | clarifies |
| `preferLazyForLongChain` | `useLazyForLongChainOps` | minor |
| `noFormatterInSwiftUIBody` | `noFormatterInViewBody` | shorter |
| `preferCompoundAssignment` | `useCompoundAssignment` | imperative |
| `noRetroactiveConformances` | `forbidRetroactiveConformances` | imperative |
| `noSortFilterInForEachData` | `noSortFilterInForEach` | shorter |
| `preferStaticOverClassFunc` | `useStaticNotClassFunc` | shorter |
| `replaceForEachWithForLoop` | `useForLoopNotForEach` | shorter |
| `preferTypedThrowsOverResult` | `useTypedThrowsNotResult` | shorter |
| `preferWhereClausesInForLoops` | `useWhereClauseInForLoop` | shorter |
| `preferContinuousClockOverDate` | `useContinuousClockNotDate` | shorter |
| `suggestOrderedSetForUniqueAppend` | `useOrderedSetForUniqueAppend` | imperative |
| `preferClosureNotificationObserver` | `useClosureNotificationObserver` | imperative |

## `lineBreaks`

| before | after | reason |
|---|---|---|
| `beforeEachArgument` | `breakBeforeEachArgument` | clarifies it's a break-policy bool |
| `elseCatchOnNewLine` | `placeElseCatchOnNewLine` | imperative |
| `modifiersOnSameLine` | `keepModifiersOnSameLine` | imperative |
| `beforeGuardConditions` | `breakBeforeGuardConditions` | imperative |
| `beforeEachGenericRequirement` | `breakBeforeGenericRequirement` | imperative |
| `betweenDeclarationAttributes` | `breakBetweenDeclAttributes` | shorter, imperative |
| `aroundMultilineExpressionChainComponents` | `breakAroundMultilineChainParts` | imperative, shorter |

## `literals`

| before | after | reason |
|---|---|---|
| `urlMacro` | `useUrlMacroForUrlLiterals` | clarifies trigger |
| `invisibleCharacters` | `flagInvisibleCharacters` | imperative |
| `noLiteralProtocolInit` | `noLiteralProtocolDirectInit` | clarifies |
| `emptyCollectionLiteral` | `flagEmptyCollectionLiteral` | imperative |
| `duplicateDictionaryKeys` | `flagDuplicateDictionaryKeys` | imperative |
| `preferEmptyCollectionForArrayArgs` | `useEmptyArrayLiteralForArgs` | clarifies, shorter |
| `multiElementCollectionTrailingCommas` | `addTrailingCommaInMultiElementColl` | imperative |

## `naming`

| before | after | reason |
|---|---|---|
| `uppercaseAcronyms` | `uppercaseAcronymsInIdentifiers` | clarifies scope |
| `asciiIdentifiers` | `requireAsciiIdentifiers` | imperative |
| `camelCaseIdentifiers` | `requireCamelCaseIdentifiers` | imperative |

## `redundancies`

This whole group is named "redundancies" (a noun). The actual rules _remove or flag_ redundant constructs. Two options:

**Option A** — rename the group to `cleanup` or `dropRedundant`, keep the keys.
**Option B** — keep the group, prefix every key with `drop…` to make the action explicit.

Recommendation: **Option B**, because the keys then read as imperatives in any UI listing.

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
| `redundantPattern` | `dropRedundantPattern` |
| `redundantEscaping` | `dropRedundantEscaping` |
| `redundantSendable` | `dropRedundantSendable` |
| `redundantLetError` | `dropRedundantLetError` |
| `redundantOverride` | `dropRedundantOverride` |
| `redundantProperty` | `dropRedundantProperty` |
| `redundantEquatable` | `dropRedundantEquatable` |
| `redundantBackticks` | `dropRedundantBackticks` |
| `redundantRawValues` | `dropRedundantRawValues` |
| `redundantSetterACL` | `dropRedundantSetterAcl` |
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

| before | after | reason |
|---|---|---|
| `spacesAroundRangeFormationOperators` | `spaceAroundRangeOperators` | shorter |

## `testing`

| before | after | reason |
|---|---|---|
| `finalTestCase` | `requireFinalOnXctestCase` | clarifies |
| **`validateTestCases`** | **`requireTestFnPrefixOrAttribute`** | matches user's example |
| `preferSwiftTesting` | `useSwiftTestingNotXctest` | clarifies |
| `testSuiteAccessControl` | `requireSuiteAccessControl` | clarifies |
| `swiftTestingTestCaseNames` | `enforceSwiftTestingNames` | imperative |

## `types`

| before | after | reason |
|---|---|---|
| **`preferAnyObject`** | **`useAnyObjectOnDelegate`** | matches user's example |
| `preferVoidReturn` | `useVoidNotEmptyTuple` | clarifies (replaces `()` with `Void` in returns) |
| `preferFailableStringInit` | `useFailableStringInit` | imperative |
| `preferShorthandTypeNames` | `useShorthandTypeNames` | imperative |
| `preferNonOptionalDataInit` | `useNonOptionalDataInit` | imperative |
| `noVoidReturnOnFunctionSignature` | `dropVoidReturnFromSignature` | shorter, imperative |
| `noTypeRepetitionInStaticProperties` | `dropTypeInStaticProperty` | shorter |

## `wrap`

The keys read as `wrap.singleLineBodies`, etc. — already imperative via the group. Recommend leaving as-is, except:

| before | after | reason |
|---|---|---|
| `keepFunctionOutputTogether` | `keepReturnTypeWithSignature` | clarifies what "output" means |

## `metrics`

All keys end in noun forms because they describe a measured thing with `error`/`warning` thresholds — that pattern is fine. **Leave as-is.**

---

## Group-name notes

Groups are mostly fine. One borderline case: **`idioms`** is a catch-all and now contains 30+ rules. Possible split (deferred):

- `swiftui` — `noFormatterInSwiftUIBody`, `preferEnvironmentEntry`, `warnForEachIDSelf`, `preferClosureNotificationObserver`, `redundantMainActorOnView`
- `collections` — all the `prefer{First,Last,All,Count,Contains,IsEmpty,IsDisjoint,FlatMap,ReduceInto,MinMax}*` rules
- `controlFlow` — `replaceForEachWithForLoop`, `preferWhereClausesInForLoops`, `noSortFilterInForEachData`
- remainder stays as `idioms`

## Migration

Add a `Configuration+Update.swift`-style migration that maps every old key → new key on load, bumps `version` to 7. Existing user configs continue to work; `sm update` writes them out renamed.
