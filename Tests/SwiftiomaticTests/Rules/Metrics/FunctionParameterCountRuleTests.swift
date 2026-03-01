import Testing
@testable import Swiftiomatic

private func funcWithParameters(
    _ parameters: String,
    violates: Bool = false,
) -> Example {
    let marker = violates ? "↓" : ""

    return Example("func \(marker)abc(\(parameters)) {}\n")
}

@Suite(.rulesRegistered) struct FunctionParameterCountRuleTests {
    @Test func functionParameterCount() async {
        let baseDescription = FunctionParameterCountRule.description
        let nonTriggeringExamples = [
            funcWithParameters(repeatElement("x: Int, ", count: 3).joined() + "x: Int"),
        ]

        let triggeringExamples = [
            funcWithParameters(repeatElement("x: Int, ", count: 5).joined() + "x: Int"),
        ]

        let description = baseDescription.with(nonTriggeringExamples: nonTriggeringExamples)
            .with(triggeringExamples: triggeringExamples)

        await verifyRule(description)
    }

    @Test func defaultFunctionParameterCount() async {
        let baseDescription = FunctionParameterCountRule.description
        let nonTriggeringExamples = [
            funcWithParameters(repeatElement("x: Int, ", count: 3).joined() + "x: Int"),
        ]

        let defaultParams = repeatElement("x: Int = 0, ", count: 2).joined() + "x: Int = 0"
        let triggeringExamples = [
            funcWithParameters(repeatElement("x: Int, ", count: 3).joined() + defaultParams),
        ]

        let description = baseDescription.with(nonTriggeringExamples: nonTriggeringExamples)
            .with(triggeringExamples: triggeringExamples)

        await verifyRule(description, ruleConfiguration: ["ignores_default_parameters": false])
    }
}
