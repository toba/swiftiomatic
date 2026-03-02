import Testing

@testable import Swiftiomatic

@Suite(.rulesRegistered) struct UnownedVariableCaptureRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(UnownedVariableCaptureRule.configuration)
  }
}

@Suite(.rulesRegistered) struct UntypedErrorInCatchRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(UntypedErrorInCatchRule.configuration)
  }
}

@Suite(.rulesRegistered) struct UnusedClosureParameterRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(UnusedClosureParameterRule.configuration)
  }
}

@Suite(.rulesRegistered) struct UnusedControlFlowLabelRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(UnusedControlFlowLabelRule.configuration)
  }
}

@Suite(.rulesRegistered) struct UnusedDeclarationRuleGeneratedTests {
  @Test(.disabled("requires sourcekitd")) func withDefaultConfiguration() async {
    await verifyRule(UnusedDeclarationRule.configuration)
  }
}

@Suite(.rulesRegistered) struct UnusedEnumeratedRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(UnusedEnumeratedRule.configuration)
  }
}

@Suite(.rulesRegistered) struct UnusedImportRuleGeneratedTests {
  @Test(.disabled("requires sourcekitd")) func withDefaultConfiguration() async {
    await verifyRule(UnusedImportRule.configuration)
  }
}

@Suite(.rulesRegistered) struct UnusedOptionalBindingRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(UnusedOptionalBindingRule.configuration)
  }
}

@Suite(.rulesRegistered) struct UnusedParameterRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(UnusedParameterRule.configuration)
  }
}

@Suite(.rulesRegistered) struct UnusedSetterValueRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(UnusedSetterValueRule.configuration)
  }
}

@Suite(.rulesRegistered) struct ValidIBInspectableRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(ValidIBInspectableRule.configuration)
  }
}

@Suite(.rulesRegistered) struct VerticalParameterAlignmentOnCallRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(VerticalParameterAlignmentOnCallRule.configuration)
  }
}

@Suite(.rulesRegistered) struct VerticalParameterAlignmentRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(VerticalParameterAlignmentRule.configuration)
  }
}

@Suite(.rulesRegistered) struct VerticalWhitespaceBetweenCasesRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(VerticalWhitespaceBetweenCasesRule.configuration)
  }
}

@Suite(.rulesRegistered) struct VerticalWhitespaceClosingBracesRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(VerticalWhitespaceClosingBracesRule.configuration)
  }
}

@Suite(.rulesRegistered) struct VerticalWhitespaceOpeningBracesRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(VerticalWhitespaceOpeningBracesRule.configuration)
  }
}

@Suite(.rulesRegistered) struct VerticalWhitespaceRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(VerticalWhitespaceRule.configuration)
  }
}

@Suite(.rulesRegistered) struct VoidFunctionInTernaryConditionRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(VoidFunctionInTernaryConditionRule.configuration)
  }
}

@Suite(.rulesRegistered) struct VoidReturnRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(VoidReturnRule.configuration)
  }
}

@Suite(.rulesRegistered) struct WeakDelegateRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(WeakDelegateRule.configuration)
  }
}

@Suite(.rulesRegistered) struct XCTFailMessageRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(XCTFailMessageRule.configuration)
  }
}

@Suite(.rulesRegistered) struct XCTSpecificMatcherRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(XCTSpecificMatcherRule.configuration)
  }
}

@Suite(.rulesRegistered) struct YodaConditionRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(YodaConditionRule.configuration)
  }
}
