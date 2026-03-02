import Testing

@testable import Swiftiomatic

@Suite(.rulesRegistered) struct RedundantObjcAttributeRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(RedundantObjcAttributeRule.self)
  }
}

@Suite(.rulesRegistered) struct RedundantSelfRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(RedundantSelfRule.self)
  }
}

@Suite(.rulesRegistered) struct RedundantSendableRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(RedundantSendableRule.self)
  }
}

@Suite(.rulesRegistered) struct RedundantSetAccessControlRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(RedundantSetAccessControlRule.self)
  }
}

@Suite(.rulesRegistered) struct RedundantStringEnumValueRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(RedundantStringEnumValueRule.self)
  }
}

@Suite(.rulesRegistered) struct RedundantTypeAnnotationRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(RedundantTypeAnnotationRule.self)
  }
}

@Suite(.rulesRegistered) struct RedundantVoidReturnRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(RedundantVoidReturnRule.self)
  }
}

@Suite(.rulesRegistered) struct RequiredDeinitRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(RequiredDeinitRule.self)
  }
}

@Suite(.rulesRegistered) struct RequiredEnumCaseRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(RequiredEnumCaseRule.self)
  }
}

@Suite(.rulesRegistered) struct ReturnArrowWhitespaceRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(ReturnArrowWhitespaceRule.self)
  }
}

@Suite(.rulesRegistered) struct ReturnValueFromVoidFunctionRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(ReturnValueFromVoidFunctionRule.self)
  }
}

@Suite(.rulesRegistered) struct SelfBindingRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(SelfBindingRule.self)
  }
}

@Suite(.rulesRegistered) struct SelfInPropertyInitializationRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(SelfInPropertyInitializationRule.self)
  }
}

@Suite(.rulesRegistered) struct ShorthandArgumentRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(ShorthandArgumentRule.self)
  }
}

@Suite(.rulesRegistered) struct ShorthandOperatorRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(ShorthandOperatorRule.self)
  }
}

@Suite(.rulesRegistered) struct ShorthandOptionalBindingRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(ShorthandOptionalBindingRule.self)
  }
}

@Suite(.rulesRegistered) struct SingleTestClassRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(SingleTestClassRule.self)
  }
}

@Suite(.rulesRegistered) struct SortedEnumCasesRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(SortedEnumCasesRule.self)
  }
}

@Suite(.rulesRegistered) struct SortedFirstLastRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(SortedFirstLastRule.self)
  }
}

@Suite(.rulesRegistered) struct SortedImportsRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(SortedImportsRule.self)
  }
}

@Suite(.rulesRegistered) struct StatementPositionRuleGeneratedTests {
  @Test(.disabled("requires sourcekitd")) func withDefaultConfiguration() async {
    await verifyRule(StatementPositionRule.self)
  }
}

@Suite(.rulesRegistered) struct StaticOperatorRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(StaticOperatorRule.self)
  }
}

@Suite(.rulesRegistered) struct StaticOverFinalClassRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(StaticOverFinalClassRule.self)
  }
}

@Suite(.rulesRegistered) struct StrictFilePrivateRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(StrictFilePrivateRule.self)
  }
}

@Suite(.rulesRegistered) struct StrongIBOutletRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(StrongIBOutletRule.self)
  }
}
