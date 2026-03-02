import Testing

@testable import Swiftiomatic

@Suite(.rulesRegistered) struct SuperfluousElseRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(SuperfluousElseRule.self)
  }
}

@Suite(.rulesRegistered) struct SwitchCaseAlignmentRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(SwitchCaseAlignmentRule.self)
  }
}

@Suite(.rulesRegistered) struct SwitchCaseOnNewlineRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(SwitchCaseOnNewlineRule.self)
  }
}

@Suite(.rulesRegistered) struct SyntacticSugarRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(SyntacticSugarRule.self)
  }
}

@Suite(.rulesRegistered) struct TestCaseAccessibilityRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(TestCaseAccessibilityRule.self)
  }
}

@Suite(.rulesRegistered) struct TodoRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(TodoRule.self)
  }
}

@Suite(.rulesRegistered) struct ToggleBoolRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(ToggleBoolRule.self)
  }
}

@Suite(.rulesRegistered) struct TrailingClosureRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(TrailingClosureRule.self)
  }
}

@Suite(.rulesRegistered) struct TrailingCommaRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(TrailingCommaRule.self)
  }
}

@Suite(.rulesRegistered) struct TrailingNewlineRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(TrailingNewlineRule.self)
  }
}

@Suite(.rulesRegistered) struct TrailingSemicolonRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(TrailingSemicolonRule.self)
  }
}

@Suite(.rulesRegistered) struct TrailingWhitespaceRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(TrailingWhitespaceRule.self)
  }
}

@Suite(.rulesRegistered) struct TypeBodyLengthRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(TypeBodyLengthRule.self)
  }
}

@Suite(.rulesRegistered) struct TypeContentsOrderRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(TypeContentsOrderRule.self)
  }
}

@Suite(.rulesRegistered) struct TypeNameRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(TypeNameRule.self)
  }
}

@Suite(.rulesRegistered) struct TypesafeArrayInitRuleGeneratedTests {
  @Test(.disabled("requires sourcekitd")) func withDefaultConfiguration() async {
    await verifyRule(TypesafeArrayInitRule.self)
  }
}

@Suite(.rulesRegistered) struct UnavailableConditionRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(UnavailableConditionRule.self)
  }
}

@Suite(.rulesRegistered) struct UnavailableFunctionRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(UnavailableFunctionRule.self)
  }
}

@Suite(.rulesRegistered) struct UnhandledThrowingTaskRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(UnhandledThrowingTaskRule.self)
  }
}

@Suite(.rulesRegistered) struct UnneededBreakInSwitchRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(UnneededBreakInSwitchRule.self)
  }
}

@Suite(.rulesRegistered) struct UnneededEscapingRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(UnneededEscapingRule.self)
  }
}

@Suite(.rulesRegistered) struct UnneededOverrideRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(UnneededOverrideRule.self)
  }
}

@Suite(.rulesRegistered) struct UnneededParenthesesInClosureArgumentRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(UnneededParenthesesInClosureArgumentRule.self)
  }
}

@Suite(.rulesRegistered) struct UnneededSynthesizedInitializerRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(UnneededSynthesizedInitializerRule.self)
  }
}

@Suite(.rulesRegistered) struct UnneededThrowsRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(UnneededThrowsRule.self)
  }
}
