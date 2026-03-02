import Testing

@testable import Swiftiomatic

@Suite(.rulesRegistered) struct EmptyParametersRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(EmptyParametersRule.self)
  }
}

@Suite(.rulesRegistered) struct EmptyParenthesesWithTrailingClosureRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(EmptyParenthesesWithTrailingClosureRule.self)
  }
}

@Suite(.rulesRegistered) struct EmptyStringRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(EmptyStringRule.self)
  }
}

@Suite(.rulesRegistered) struct EmptyXCTestMethodRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(EmptyXCTestMethodRule.self)
  }
}

@Suite(.rulesRegistered) struct EnumCaseAssociatedValuesLengthRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(EnumCaseAssociatedValuesLengthRule.self)
  }
}

@Suite(.rulesRegistered) struct ExpiringTodoRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(ExpiringTodoRule.self)
  }
}

@Suite(.rulesRegistered) struct ExplicitACLRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(ExplicitACLRule.self)
  }
}

@Suite(.rulesRegistered) struct ExplicitEnumRawValueRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(ExplicitEnumRawValueRule.self)
  }
}

@Suite(.rulesRegistered) struct ExplicitInitRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(ExplicitInitRule.self)
  }
}

@Suite(.rulesRegistered) struct ExplicitSelfRuleGeneratedTests {
  @Test(.disabled("requires sourcekitd")) func withDefaultConfiguration() async {
    await verifyRule(ExplicitSelfRule.self)
  }
}

@Suite(.rulesRegistered) struct ExplicitTopLevelACLRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(ExplicitTopLevelACLRule.self)
  }
}

@Suite(.rulesRegistered) struct ExplicitTypeInterfaceRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(ExplicitTypeInterfaceRule.self)
  }
}

@Suite(.rulesRegistered) struct ExtensionAccessModifierRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(ExtensionAccessModifierRule.self)
  }
}

@Suite(.rulesRegistered) struct FallthroughRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(FallthroughRule.self)
  }
}

@Suite(.rulesRegistered) struct FatalErrorMessageRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(FatalErrorMessageRule.self)
  }
}

@Suite(.rulesRegistered) struct FileHeaderRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(FileHeaderRule.self)
  }
}

@Suite(.rulesRegistered) struct FileLengthRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(FileLengthRule.self)
  }
}

@Suite(.rulesRegistered) struct FileNameNoSpaceRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(FileNameNoSpaceRule.self)
  }
}

@Suite(.rulesRegistered) struct FileNameRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(FileNameRule.self)
  }
}

@Suite(.rulesRegistered) struct FileTypesOrderRuleGeneratedTests {
  @Test(.disabled("requires sourcekitd")) func withDefaultConfiguration() async {
    await verifyRule(FileTypesOrderRule.self)
  }
}

@Suite(.rulesRegistered) struct FinalTestCaseRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(FinalTestCaseRule.self)
  }
}

@Suite(.rulesRegistered) struct FirstWhereRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(FirstWhereRule.self)
  }
}

@Suite(.rulesRegistered) struct FlatMapOverMapReduceRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(FlatMapOverMapReduceRule.self)
  }
}

@Suite(.rulesRegistered) struct ForWhereRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(ForWhereRule.self)
  }
}

@Suite(.rulesRegistered) struct ForceCastRuleGeneratedTests {
  @Test func withDefaultConfiguration() async {
    await verifyRule(ForceCastRule.self)
  }
}
