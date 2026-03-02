import Testing

@testable import Swiftiomatic

@Suite(.rulesRegistered) struct EmptyParametersRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(EmptyParametersRule.configuration)
  }
}

@Suite(.rulesRegistered) struct EmptyParenthesesWithTrailingClosureRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(EmptyParenthesesWithTrailingClosureRule.configuration)
  }
}

@Suite(.rulesRegistered) struct EmptyStringRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(EmptyStringRule.configuration)
  }
}

@Suite(.rulesRegistered) struct EmptyXCTestMethodRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(EmptyXCTestMethodRule.configuration)
  }
}

@Suite(.rulesRegistered) struct EnumCaseAssociatedValuesLengthRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(EnumCaseAssociatedValuesLengthRule.configuration)
  }
}

@Suite(.rulesRegistered) struct ExpiringTodoRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(ExpiringTodoRule.configuration)
  }
}

@Suite(.rulesRegistered) struct ExplicitACLRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(ExplicitACLRule.configuration)
  }
}

@Suite(.rulesRegistered) struct ExplicitEnumRawValueRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(ExplicitEnumRawValueRule.configuration)
  }
}

@Suite(.rulesRegistered) struct ExplicitInitRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(ExplicitInitRule.configuration)
  }
}

@Suite(.rulesRegistered) struct ExplicitSelfRuleGeneratedTests {
  @Test(.disabled("requires sourcekitd")) func withDefaultConfiguration() async {
    await verifyRule(ExplicitSelfRule.configuration)
  }
}

@Suite(.rulesRegistered) struct ExplicitTopLevelACLRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(ExplicitTopLevelACLRule.configuration)
  }
}

@Suite(.rulesRegistered) struct ExplicitTypeInterfaceRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(ExplicitTypeInterfaceRule.configuration)
  }
}

@Suite(.rulesRegistered) struct ExtensionAccessModifierRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(ExtensionAccessModifierRule.configuration)
  }
}

@Suite(.rulesRegistered) struct FallthroughRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(FallthroughRule.configuration)
  }
}

@Suite(.rulesRegistered) struct FatalErrorMessageRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(FatalErrorMessageRule.configuration)
  }
}

@Suite(.rulesRegistered) struct FileHeaderRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(FileHeaderRule.configuration)
  }
}

@Suite(.rulesRegistered) struct FileLengthRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(FileLengthRule.configuration)
  }
}

@Suite(.rulesRegistered) struct FileNameNoSpaceRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(FileNameNoSpaceRule.configuration)
  }
}

@Suite(.rulesRegistered) struct FileNameRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(FileNameRule.configuration)
  }
}

@Suite(.rulesRegistered) struct FileTypesOrderRuleGeneratedTests {
  @Test(.disabled("requires sourcekitd")) func withDefaultConfiguration() async {
    await verifyRule(FileTypesOrderRule.configuration)
  }
}

@Suite(.rulesRegistered) struct FinalTestCaseRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(FinalTestCaseRule.configuration)
  }
}

@Suite(.rulesRegistered) struct FirstWhereRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(FirstWhereRule.configuration)
  }
}

@Suite(.rulesRegistered) struct FlatMapOverMapReduceRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(FlatMapOverMapReduceRule.configuration)
  }
}

@Suite(.rulesRegistered) struct ForWhereRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(ForWhereRule.configuration)
  }
}

@Suite(.rulesRegistered) struct ForceCastRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(ForceCastRule.configuration)
  }
}
