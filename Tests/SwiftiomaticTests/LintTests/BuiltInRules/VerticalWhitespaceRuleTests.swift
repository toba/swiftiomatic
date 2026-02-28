import Testing
@testable import Swiftiomatic

@Suite struct VerticalWhitespaceRuleTests {
    init() { RuleRegistry.registerAllRulesOnce() }

    private let ruleID = VerticalWhitespaceRule.identifier

    @Test func attributesWithMaxEmptyLines() {
        // Test with custom `max_empty_lines`
        let maxEmptyLinesDescription = VerticalWhitespaceRule.description
            .with(nonTriggeringExamples: [Example("let aaaa = 0\n\n\n")])
            .with(triggeringExamples: [
                Example("struct AAAA {}\n\n\n\n"),
                Example("class BBBB {\n  \n  \n  \n}"),
            ])
            .with(corrections: [:])

        verifyRule(maxEmptyLinesDescription,
                   ruleConfiguration: ["max_empty_lines": 2])
    }

    @Test func autoCorrectionWithMaxEmptyLines() {
        let maxEmptyLinesDescription = VerticalWhitespaceRule.description
            .with(nonTriggeringExamples: [])
            .with(triggeringExamples: [])
            .with(corrections: [
                Example("let b = 0\n\n↓\n↓\n↓\n\nclass AAA {}\n"): Example("let b = 0\n\n\nclass AAA {}\n"),
                Example("let b = 0\n\n\nclass AAA {}\n"): Example("let b = 0\n\n\nclass AAA {}\n"),
                Example("class BB {\n  \n  \n↓  \n  let b = 0\n}\n"): Example("class BB {\n  \n  \n  let b = 0\n}\n"),
            ])

        verifyRule(maxEmptyLinesDescription,
                   ruleConfiguration: ["max_empty_lines": 2])
    }

    @Test func violationMessageWithMaxEmptyLines() {
        guard let config = makeConfig(["max_empty_lines": 2], ruleID) else {
            Issue.record("Failed to create configuration")
            return
        }
        let allViolations = violations(Example("let aaaa = 0\n\n\n\nlet bbb = 2\n"), config: config)

        let verticalWhiteSpaceViolation = allViolations.first { $0.ruleIdentifier == ruleID }
        if let violation = verticalWhiteSpaceViolation {
            #expect(violation.reason == "Limit vertical whitespace to maximum 2 empty lines; currently 3")
        } else {
            Issue.record("A vertical whitespace violation should have been triggered!")
        }
    }

    @Test func violationMessageWithDefaultConfiguration() {
        let allViolations = violations(Example("let aaaa = 0\n\n\n\nlet bbb = 2\n"))
        let verticalWhiteSpaceViolation = allViolations.first(where: { $0.ruleIdentifier == ruleID })
        if let violation = verticalWhiteSpaceViolation {
            #expect(violation.reason == "Limit vertical whitespace to a single empty line; currently 3")
        } else {
            Issue.record("A vertical whitespace violation should have been triggered!")
        }
    }
}
