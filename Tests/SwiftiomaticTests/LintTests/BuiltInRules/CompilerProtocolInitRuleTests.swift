import Testing
@testable import Swiftiomatic

@Suite struct CompilerProtocolInitRuleTests {
    init() { RuleRegistry.registerAllRulesOnce() }

    private let ruleID = CompilerProtocolInitRule.identifier

    @Test func violationMessageForExpressibleByIntegerLiteral() throws {
        let config = try #require(makeConfig(nil, ruleID))
        let allViolations = violations(Example("let a = NSNumber(integerLiteral: 1)"), config: config)

        let compilerProtocolInitViolation = allViolations.first { $0.ruleIdentifier == ruleID }
        let violation = try #require(
            compilerProtocolInitViolation,
            "A compiler protocol init violation should have been triggered!"
        )
        #expect(violation.reason == "Initializers declared in compiler protocol ExpressibleByIntegerLiteral shouldn't be called directly")
    }
}
