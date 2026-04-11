import Testing

@testable import SwiftiomaticKit

@Suite(.rulesRegistered) struct AcronymsRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(AcronymsRule.self)
  }
}

@Suite(.rulesRegistered) struct AgentReviewRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(AgentReviewRule.self)
  }
}

@Suite(.rulesRegistered) struct AndOperatorRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(AndOperatorRule.self)
  }
}

@Suite(.rulesRegistered) struct AnyEliminationRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(AnyEliminationRule.self)
  }
}

@Suite(.rulesRegistered) struct AnyObjectProtocolRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(AnyObjectProtocolRule.self)
  }
}

@Suite(.rulesRegistered) struct ApplicationMainRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(ApplicationMainRule.self)
  }
}
@Suite(.rulesRegistered) struct BlankLineAfterImportsRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(BlankLineAfterImportsRule.self)
  }
}

@Suite(.rulesRegistered) struct BlankLinesAfterGuardStatementsRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(BlankLinesAfterGuardStatementsRule.self)
  }
}

@Suite(.rulesRegistered) struct BlankLinesAroundMarkRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(BlankLinesAroundMarkRule.self)
  }
}

@Suite(.rulesRegistered) struct BlankLinesBetweenChainedFunctionsRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(BlankLinesBetweenChainedFunctionsRule.self)
  }
}

@Suite(.rulesRegistered) struct BlankLinesBetweenImportsRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(BlankLinesBetweenImportsRule.self)
  }
}

@Suite(.rulesRegistered) struct BlankLinesBetweenScopesRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(BlankLinesBetweenScopesRule.self)
  }
}

@Suite(.rulesRegistered) struct BlockCommentsRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(BlockCommentsRule.self)
  }
}

@Suite(.rulesRegistered) struct CaseIterableUsageRuleGeneratedTests {
  @Test(.disabled("collecting rule")) func withDefaultConfiguration() async {
    await verifyRule(CaseIterableUsageRule.self)
  }
}

@Suite(.rulesRegistered) struct ConcurrencyModernizationRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(ConcurrencyModernizationRule.self)
  }
}

@Suite(.rulesRegistered) struct ConditionalAssignmentRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(ConditionalAssignmentRule.self)
  }
}

@Suite(.rulesRegistered) struct ConsecutiveSpacesRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(ConsecutiveSpacesRule.self)
  }
}

@Suite(.rulesRegistered) struct DeadSymbolsRuleGeneratedTests {
  @Test(.disabled("collecting rule")) func withDefaultConfiguration() async {
    await verifyRule(DeadSymbolsRule.self)
  }
}

@Suite(.rulesRegistered) struct DelegateToAsyncStreamRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(DelegateToAsyncStreamRule.self)
  }
}

@Suite(.rulesRegistered) struct DocCommentsBeforeModifiersRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(DocCommentsBeforeModifiersRule.self)
  }
}

@Suite(.rulesRegistered) struct DocCommentsRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(DocCommentsRule.self)
  }
}

@Suite(.rulesRegistered) struct EmptyBracesRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(EmptyBracesRule.self)
  }
}

@Suite(.rulesRegistered) struct EmptyExtensionsRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(EmptyExtensionsRule.self)
  }
}

@Suite(.rulesRegistered) struct EnumNamespacesRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(EnumNamespacesRule.self)
  }
}

@Suite(.rulesRegistered) struct EnvironmentEntryRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(EnvironmentEntryRule.self)
  }
}

@Suite(.rulesRegistered) struct ExtensionAccessControlRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(ExtensionAccessControlRule.self)
  }
}

@Suite(.rulesRegistered) struct FileMacroRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(FileMacroRule.self)
  }
}

@Suite(.rulesRegistered) struct FireAndForgetTaskRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(FireAndForgetTaskRule.self)
  }
}

@Suite(.rulesRegistered) struct GenericConsolidationRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(GenericConsolidationRule.self)
  }
}

@Suite(.rulesRegistered) struct GenericExtensionsRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(GenericExtensionsRule.self)
  }
}

@Suite(.rulesRegistered) struct HeaderFileNameRuleGeneratedTests {
  @Test(
    .disabled(
      "requiresFileOnDisk with UUID temp paths — examples need file_name config that verifyRule cannot provide"
    )) func withDefaultConfiguration() async
  {
    await verifyRule(HeaderFileNameRule.self)
  }
}

@Suite(.rulesRegistered) struct HoistAwaitRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(HoistAwaitRule.self)
  }
}

@Suite(.rulesRegistered) struct HoistTryRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(HoistTryRule.self)
  }
}
@Suite(.rulesRegistered) struct LeadingDelimitersRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(LeadingDelimitersRule.self)
  }
}

@Suite(.rulesRegistered) struct LinebreaksRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(LinebreaksRule.self)
  }
}

@Suite(.rulesRegistered) struct MarkTypesRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(MarkTypesRule.self)
  }
}

@Suite(.rulesRegistered) struct ModifiersOnSameLineRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(ModifiersOnSameLineRule.self)
  }
}

@Suite(.rulesRegistered) struct NamingHeuristicsRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(NamingHeuristicsRule.self)
  }
}

@Suite(.rulesRegistered) struct NoExplicitOwnershipRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(NoExplicitOwnershipRule.self)
  }
}

@Suite(.rulesRegistered) struct NoForceTryInTestsRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(NoForceTryInTestsRule.self)
  }
}

@Suite(.rulesRegistered) struct NoForceUnwrapInTestsRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(NoForceUnwrapInTestsRule.self)
  }
}

@Suite(.rulesRegistered) struct NoGuardInTestsRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(NoGuardInTestsRule.self)
  }
}
@Suite(.rulesRegistered) struct ObservationPitfallsRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(ObservationPitfallsRule.self)
  }
}
@Suite(.rulesRegistered) struct DateForTimingRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(DateForTimingRule.self)
  }
}

@Suite(.rulesRegistered) struct InlinableGenericRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(InlinableGenericRule.self)
  }
}

@Suite(.rulesRegistered) struct LazyChainRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(LazyChainRule.self)
  }
}

@Suite(.rulesRegistered) struct LockAntiPatternsRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(LockAntiPatternsRule.self)
  }
}

@Suite(.rulesRegistered) struct MutationDuringIterationRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(MutationDuringIterationRule.self)
  }
}

@Suite(.rulesRegistered) struct PreferCountWhereRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(PreferCountWhereRule.self)
  }
}

@Suite(.rulesRegistered) struct PreferFinalClassesRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(PreferFinalClassesRule.self)
  }
}

@Suite(.rulesRegistered) struct PreferForLoopRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(PreferForLoopRule.self)
  }
}

@Suite(.rulesRegistered) struct PreferSwiftTestingRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(PreferSwiftTestingRule.self)
  }
}

@Suite(.rulesRegistered) struct RedundantBackticksRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(RedundantBackticksRule.self)
  }
}

@Suite(.rulesRegistered) struct RedundantClosureRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(RedundantClosureRule.self)
  }
}

@Suite(.rulesRegistered) struct RedundantEquatableRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(RedundantEquatableRule.self)
  }
}

@Suite(.rulesRegistered) struct RedundantExtensionACLRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(RedundantExtensionACLRule.self)
  }
}

@Suite(.rulesRegistered) struct UnnecessaryFileprivateRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(UnnecessaryFileprivateRule.self)
  }
}

@Suite(.rulesRegistered) struct RedundantGetRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(RedundantGetRule.self)
  }
}

@Suite(.rulesRegistered) struct RedundantInternalRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(RedundantInternalRule.self)
  }
}
@Suite(.rulesRegistered) struct RedundantParensRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(RedundantParensRule.self)
  }
}

@Suite(.rulesRegistered) struct RedundantPropertyRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(RedundantPropertyRule.self)
  }
}

@Suite(.rulesRegistered) struct RedundantPublicRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(RedundantPublicRule.self)
  }
}
@Suite(.rulesRegistered) struct RedundantStaticSelfRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(RedundantStaticSelfRule.self)
  }
}

@Suite(.rulesRegistered) struct RedundantViewBuilderRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(RedundantViewBuilderRule.self)
  }
}

@Suite(.rulesRegistered) struct SimplifyGenericConstraintsRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(SimplifyGenericConstraintsRule.self)
  }
}

@Suite(.rulesRegistered) struct SinglePropertyPerLineRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(SinglePropertyPerLineRule.self)
  }
}

@Suite(.rulesRegistered) struct SortDeclarationsRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(SortDeclarationsRule.self)
  }
}

@Suite(.rulesRegistered) struct SortImportsRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(SortImportsRule.self)
  }
}

@Suite(.rulesRegistered) struct SortSwitchCasesRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(SortSwitchCasesRule.self)
  }
}

@Suite(.rulesRegistered) struct SortTypealiasesRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(SortTypealiasesRule.self)
  }
}

@Suite(.rulesRegistered) struct SpaceAroundBracketsRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(SpaceAroundBracketsRule.self)
  }
}

@Suite(.rulesRegistered) struct SpaceAroundCommentsRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(SpaceAroundCommentsRule.self)
  }
}

@Suite(.rulesRegistered) struct SpaceAroundGenericsRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(SpaceAroundGenericsRule.self)
  }
}

@Suite(.rulesRegistered) struct SpaceAroundParensRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(SpaceAroundParensRule.self)
  }
}

@Suite(.rulesRegistered) struct SpaceInsideBracketsRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(SpaceInsideBracketsRule.self)
  }
}

@Suite(.rulesRegistered) struct SpaceInsideGenericsRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(SpaceInsideGenericsRule.self)
  }
}

@Suite(.rulesRegistered) struct SpaceInsideParensRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(SpaceInsideParensRule.self)
  }
}

@Suite(.rulesRegistered) struct StrongifiedSelfRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(StrongifiedSelfRule.self)
  }
}

@Suite(.rulesRegistered) struct StructuralDuplicationRuleGeneratedTests {
  @Test(.disabled("collecting rule")) func withDefaultConfiguration() async {
    await verifyRule(StructuralDuplicationRule.self)
  }
}

@Suite(.rulesRegistered) struct Swift62ModernizationRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(Swift62ModernizationRule.self)
  }
}

@Suite(.rulesRegistered) struct SwiftTestingTestCaseNamesRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(SwiftTestingTestCaseNamesRule.self)
  }
}

@Suite(.rulesRegistered) struct SwiftUILayoutRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(SwiftUILayoutRule.self)
  }
}

@Suite(.rulesRegistered) struct TypedThrowsRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(TypedThrowsRule.self)
  }
}

@Suite(.rulesRegistered) struct URLMacroRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(URLMacroRule.self)
  }
}

@Suite(.rulesRegistered) struct ValidateTestCasesRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(ValidateTestCasesRule.self)
  }
}

@Suite(.rulesRegistered) struct PreferWeakLetRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(PreferWeakLetRule.self)
  }
}
