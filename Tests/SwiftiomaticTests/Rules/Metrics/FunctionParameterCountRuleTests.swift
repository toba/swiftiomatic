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
    let nonTriggeringExamples = [
      funcWithParameters(repeatElement("x: Int, ", count: 3).joined() + "x: Int")
    ]

    let triggeringExamples = [
      funcWithParameters(repeatElement("x: Int, ", count: 5).joined() + "x: Int")
    ]

    let description = TestExamples(from: FunctionParameterCountRule.self).with(
      nonTriggeringExamples: nonTriggeringExamples,
      triggeringExamples: triggeringExamples,
    )

    await verifyRule(description)
  }

  @Test func defaultFunctionParameterCount() async {
    let nonTriggeringExamples = [
      funcWithParameters(repeatElement("x: Int, ", count: 3).joined() + "x: Int")
    ]

    let defaultParams = repeatElement("x: Int = 0, ", count: 2).joined() + "x: Int = 0"
    let triggeringExamples = [
      funcWithParameters(repeatElement("x: Int, ", count: 3).joined() + defaultParams)
    ]

    let description = TestExamples(from: FunctionParameterCountRule.self).with(
      nonTriggeringExamples: nonTriggeringExamples,
      triggeringExamples: triggeringExamples,
    )

    await verifyRule(description, ruleConfiguration: ["ignores_default_parameters": false])
  }
}
