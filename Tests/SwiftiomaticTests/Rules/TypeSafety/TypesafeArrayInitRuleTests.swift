import Testing

@testable import SwiftiomaticKit
@testable import SwiftiomaticSyntax

@Suite(.rulesRegistered, .disabled("requires sourcekitd")) struct TypesafeArrayInitRuleTests {
  @Test func violationRuleIdentifier() async {
    let baseExamples = TestExamples(from: TypesafeArrayInitRule.self)
    guard let triggeringExample = baseExamples.triggeringExamples.first else {
      Issue.record("No triggering examples found")
      return
    }
    guard let config = makeConfig(nil, baseExamples.identifier) else {
      Issue.record("Failed to create configuration")
      return
    }
    let allViolations = await violations(
      triggeringExample, config: config, requiresFileOnDisk: true)
    #expect(allViolations.count >= 1)
    #expect(allViolations.first?.ruleIdentifier == baseExamples.identifier)
  }
}
