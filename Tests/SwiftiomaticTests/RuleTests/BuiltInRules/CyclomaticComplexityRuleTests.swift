import Testing
@testable import Swiftiomatic

@Suite struct CyclomaticComplexityRuleTests {
    init() { RuleRegistry.registerAllRulesOnce() }

    private var complexSwitchExample: Example {
        var example = "func switcheroo() {\n"
        example += "    switch foo {\n"
        for index in 0 ... 30 {
            example += "  case \(index):   print(\"\(index)\")\n"
        }
        example += "    }\n"
        example += "}\n"
        return Example(example)
    }

    private var complexSwitchInitExample: Example {
        var example = "init() {\n"
        example += "    switch foo {\n"
        for index in 0 ... 30 {
            example += "  case \(index):   print(\"\(index)\")\n"
        }
        example += "    }\n"
        example += "}\n"
        return Example(example)
    }

    private var complexIfExample: Example {
        let nest = 22
        var example = "func nestThoseIfs() {\n"
        for index in 0 ... nest {
            let indent = String(repeating: "    ", count: index + 1)
            example += indent + "if false != true {\n"
            example += indent + "   print \"\\(i)\"\n"
        }

        for index in (0 ... nest).reversed() {
            let indent = String(repeating: "    ", count: index + 1)
            example += indent + "}\n"
        }
        example += "}\n"
        return Example(example)
    }

    @Test func cyclomaticComplexity() {
        verifyRule(
            CyclomaticComplexityRule.description, commentDoesNotViolate: true,
            stringDoesNotViolate: true,
        )
    }

    @Test func ignoresCaseStatementsConfigurationEnabled() {
        let baseDescription = CyclomaticComplexityRule.description
        let triggeringExamples = [complexIfExample]
        let nonTriggeringExamples = baseDescription.nonTriggeringExamples + [complexSwitchExample]

        let description = baseDescription.with(nonTriggeringExamples: nonTriggeringExamples)
            .with(triggeringExamples: triggeringExamples)

        verifyRule(
            description, ruleConfiguration: ["ignores_case_statements": true],
            commentDoesNotViolate: true, stringDoesNotViolate: true,
        )
    }

    @Test func ignoresCaseStatementsConfigurationDisabled() {
        let baseDescription = CyclomaticComplexityRule.description
        let triggeringExamples =
            baseDescription.triggeringExamples + [complexSwitchExample, complexSwitchInitExample]
        let nonTriggeringExamples = baseDescription.nonTriggeringExamples

        let description = baseDescription.with(nonTriggeringExamples: nonTriggeringExamples)
            .with(triggeringExamples: triggeringExamples)

        verifyRule(
            description, ruleConfiguration: ["ignores_case_statements": false],
            commentDoesNotViolate: true, stringDoesNotViolate: true,
        )
    }
}
