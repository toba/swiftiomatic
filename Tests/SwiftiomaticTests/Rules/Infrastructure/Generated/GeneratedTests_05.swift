import Testing

@testable import Swiftiomatic

@Suite(.rulesRegistered) struct LegacyConstructorRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(LegacyConstructorRule.self)
  }
}

@Suite(.rulesRegistered) struct LegacyHashingRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(LegacyHashingRule.self)
  }
}

@Suite(.rulesRegistered) struct LegacyMultipleRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(LegacyMultipleRule.self)
  }
}

@Suite(.rulesRegistered) struct LegacyNSGeometryFunctionsRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(LegacyNSGeometryFunctionsRule.self)
  }
}

@Suite(.rulesRegistered) struct LegacyObjcTypeRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(LegacyObjcTypeRule.self)
  }
}

@Suite(.rulesRegistered) struct LegacyRandomRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(LegacyRandomRule.self)
  }
}

@Suite(.rulesRegistered) struct LetVarWhitespaceRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(LetVarWhitespaceRule.self)
  }
}

@Suite(.rulesRegistered) struct LineLengthRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(LineLengthRule.self)
  }
}

@Suite(.rulesRegistered) struct LiteralExpressionEndIndentationRuleGeneratedTests {
  @Test(.disabled("requires sourcekitd")) func withDefaultConfiguration() async {
    await verifyRule(LiteralExpressionEndIndentationRule.self)
  }
}

@Suite(.rulesRegistered) struct LocalDocCommentRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(LocalDocCommentRule.self)
  }
}

@Suite(.rulesRegistered) struct LowerACLThanParentRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(LowerACLThanParentRule.self)
  }
}

@Suite(.rulesRegistered) struct MarkRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(MarkRule.self)
  }
}

@Suite(.rulesRegistered) struct MissingDocsRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(MissingDocsRule.self)
  }
}

@Suite(.rulesRegistered) struct ModifierOrderRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(ModifierOrderRule.self)
  }
}

@Suite(.rulesRegistered) struct MultilineArgumentsBracketsRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(MultilineArgumentsBracketsRule.self)
  }
}

@Suite(.rulesRegistered) struct MultilineArgumentsRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(MultilineArgumentsRule.self)
  }
}

@Suite(.rulesRegistered) struct MultilineCallArgumentsRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(MultilineCallArgumentsRule.self)
  }
}

@Suite(.rulesRegistered) struct MultilineFunctionChainsRuleGeneratedTests {
  @Test(.disabled("requires sourcekitd")) func withDefaultConfiguration() async {
    await verifyRule(MultilineFunctionChainsRule.self)
  }
}

@Suite(.rulesRegistered) struct MultilineLiteralBracketsRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(MultilineLiteralBracketsRule.self)
  }
}

@Suite(.rulesRegistered) struct MultilineParametersBracketsRuleGeneratedTests {
  @Test(.disabled("requires sourcekitd")) func withDefaultConfiguration() async {
    await verifyRule(MultilineParametersBracketsRule.self)
  }
}

@Suite(.rulesRegistered) struct MultilineParametersRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(MultilineParametersRule.self)
  }
}

@Suite(.rulesRegistered) struct MultipleClosuresWithTrailingClosureRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(MultipleClosuresWithTrailingClosureRule.self)
  }
}

@Suite(.rulesRegistered) struct NSLocalizedStringKeyRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(NSLocalizedStringKeyRule.self)
  }
}

@Suite(.rulesRegistered) struct NSLocalizedStringRequireBundleRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(NSLocalizedStringRequireBundleRule.self)
  }
}

@Suite(.rulesRegistered) struct NSNumberInitAsFunctionReferenceRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(NSNumberInitAsFunctionReferenceRule.self)
  }
}
