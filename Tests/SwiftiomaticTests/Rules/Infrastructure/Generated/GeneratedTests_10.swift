import Testing
@testable import Swiftiomatic

@Suite(.rulesRegistered) struct UnownedVariableCaptureRuleGeneratedTests {
    @Test func withDefaultConfiguration() async {
        await verifyRule(UnownedVariableCaptureRule.description)
    }
}

@Suite(.rulesRegistered) struct UntypedErrorInCatchRuleGeneratedTests {
    @Test func withDefaultConfiguration() async {
        await verifyRule(UntypedErrorInCatchRule.description)
    }
}

@Suite(.rulesRegistered) struct UnusedClosureParameterRuleGeneratedTests {
    @Test func withDefaultConfiguration() async {
        await verifyRule(UnusedClosureParameterRule.description)
    }
}

@Suite(.rulesRegistered) struct UnusedControlFlowLabelRuleGeneratedTests {
    @Test func withDefaultConfiguration() async {
        await verifyRule(UnusedControlFlowLabelRule.description)
    }
}

@Suite(.rulesRegistered) struct UnusedDeclarationRuleGeneratedTests {
    @Test(.disabled("requires sourcekitd")) func withDefaultConfiguration() async {
        await verifyRule(UnusedDeclarationRule.description)
    }
}

@Suite(.rulesRegistered) struct UnusedEnumeratedRuleGeneratedTests {
    @Test func withDefaultConfiguration() async {
        await verifyRule(UnusedEnumeratedRule.description)
    }
}

@Suite(.rulesRegistered) struct UnusedImportRuleGeneratedTests {
    @Test(.disabled("requires sourcekitd")) func withDefaultConfiguration() async {
        await verifyRule(UnusedImportRule.description)
    }
}

@Suite(.rulesRegistered) struct UnusedOptionalBindingRuleGeneratedTests {
    @Test func withDefaultConfiguration() async {
        await verifyRule(UnusedOptionalBindingRule.description)
    }
}

@Suite(.rulesRegistered) struct UnusedParameterRuleGeneratedTests {
    @Test func withDefaultConfiguration() async {
        await verifyRule(UnusedParameterRule.description)
    }
}

@Suite(.rulesRegistered) struct UnusedSetterValueRuleGeneratedTests {
    @Test func withDefaultConfiguration() async {
        await verifyRule(UnusedSetterValueRule.description)
    }
}

@Suite(.rulesRegistered) struct ValidIBInspectableRuleGeneratedTests {
    @Test func withDefaultConfiguration() async {
        await verifyRule(ValidIBInspectableRule.description)
    }
}

@Suite(.rulesRegistered) struct VerticalParameterAlignmentOnCallRuleGeneratedTests {
    @Test func withDefaultConfiguration() async {
        await verifyRule(VerticalParameterAlignmentOnCallRule.description)
    }
}

@Suite(.rulesRegistered) struct VerticalParameterAlignmentRuleGeneratedTests {
    @Test func withDefaultConfiguration() async {
        await verifyRule(VerticalParameterAlignmentRule.description)
    }
}

@Suite(.rulesRegistered) struct VerticalWhitespaceBetweenCasesRuleGeneratedTests {
    @Test func withDefaultConfiguration() async {
        await verifyRule(VerticalWhitespaceBetweenCasesRule.description)
    }
}

@Suite(.rulesRegistered) struct VerticalWhitespaceClosingBracesRuleGeneratedTests {
    @Test func withDefaultConfiguration() async {
        await verifyRule(VerticalWhitespaceClosingBracesRule.description)
    }
}

@Suite(.rulesRegistered) struct VerticalWhitespaceOpeningBracesRuleGeneratedTests {
    @Test func withDefaultConfiguration() async {
        await verifyRule(VerticalWhitespaceOpeningBracesRule.description)
    }
}

@Suite(.rulesRegistered) struct VerticalWhitespaceRuleGeneratedTests {
    @Test func withDefaultConfiguration() async {
        await verifyRule(VerticalWhitespaceRule.description)
    }
}

@Suite(.rulesRegistered) struct VoidFunctionInTernaryConditionRuleGeneratedTests {
    @Test func withDefaultConfiguration() async {
        await verifyRule(VoidFunctionInTernaryConditionRule.description)
    }
}

@Suite(.rulesRegistered) struct VoidReturnRuleGeneratedTests {
    @Test func withDefaultConfiguration() async {
        await verifyRule(VoidReturnRule.description)
    }
}

@Suite(.rulesRegistered) struct WeakDelegateRuleGeneratedTests {
    @Test func withDefaultConfiguration() async {
        await verifyRule(WeakDelegateRule.description)
    }
}

@Suite(.rulesRegistered) struct XCTFailMessageRuleGeneratedTests {
    @Test func withDefaultConfiguration() async {
        await verifyRule(XCTFailMessageRule.description)
    }
}

@Suite(.rulesRegistered) struct XCTSpecificMatcherRuleGeneratedTests {
    @Test func withDefaultConfiguration() async {
        await verifyRule(XCTSpecificMatcherRule.description)
    }
}

@Suite(.rulesRegistered) struct YodaConditionRuleGeneratedTests {
    @Test func withDefaultConfiguration() async {
        await verifyRule(YodaConditionRule.description)
    }
}
