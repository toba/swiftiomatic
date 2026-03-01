import Testing

@testable import Swiftiomatic

@Suite(.rulesRegistered) struct RuleTests {
  fileprivate struct RuleMock1: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)
    var configurationDescription: some Documentable { RuleConfigurationOption.noOptions }
    static let description = RuleDescription(
      identifier: "RuleMock1", name: "",
      description: "",
    )

    init() { /* conformance for test */  }
    init(configuration _: Any) { self.init() }

    func validate(file _: SwiftSource) -> [RuleViolation] {
      []
    }
  }

  fileprivate struct RuleMock2: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)
    var configurationDescription: some Documentable { RuleConfigurationOption.noOptions }
    static let description = RuleDescription(
      identifier: "RuleMock2", name: "",
      description: "",
    )

    init() { /* conformance for test */  }
    init(configuration _: Any) { self.init() }

    func validate(file _: SwiftSource) -> [RuleViolation] {
      []
    }
  }

  fileprivate struct RuleWithLevelsMock2: Rule {
    var configuration = SeverityLevelsConfiguration<Self>(warning: 2, error: 3)

    static let description = RuleDescription(
      identifier: "violation_level_mock2",
      name: "",
      description: "",
    )

    init() { /* conformance for test */  }
    init(configuration: Any) throws {
      self.init()
      let normalized: [String: Any]
      if let dict = configuration as? [String: Any] {
        normalized = dict
      } else if let array = configuration as? [Int] {
        normalized = ["_values": array]
      } else if let value = configuration as? Int {
        normalized = ["_values": [value]]
      } else {
        throw SwiftiomaticError.invalidConfiguration(ruleID: Self.identifier)
      }
      try self.configuration.apply(configuration: normalized)
    }

    func validate(file _: SwiftSource) -> [RuleViolation] { [] }
  }

  @Test func ruleIsEqualTo() {
    #expect(RuleMock1().isEqualTo(RuleMock1()))
  }

  @Test func ruleIsNotEqualTo() {
    #expect(!(RuleMock1().isEqualTo(RuleMock2())))
  }

  @Test func ruleArraysWithDifferentCountsNotEqual() {
    #expect(!([RuleMock1(), RuleMock2()] == [RuleMock1()]))
  }

  @Test func severityLevelRuleInitsWithConfigDictionary() {
    let config = ["warning": 17, "error": 7]
    let rule = try? RuleWithLevelsMock(configuration: config)
    var comp = RuleWithLevelsMock()
    comp.configuration.warning = 17
    comp.configuration.error = 7
    #expect(rule?.isEqualTo(comp) == true)
  }

  @Test func severityLevelRuleInitsWithWarningOnlyConfigDictionary() {
    let config = ["warning": 17]
    let rule = try? RuleWithLevelsMock(configuration: config)
    var comp = RuleWithLevelsMock()
    comp.configuration.warning = 17
    comp.configuration.error = nil
    #expect(rule?.isEqualTo(comp) == true)
  }

  @Test func severityLevelRuleInitsWithErrorOnlyConfigDictionary() {
    let config = ["error": 17]
    let rule = try? RuleWithLevelsMock(configuration: config)
    var comp = RuleWithLevelsMock()
    comp.configuration.error = 17
    #expect(rule?.isEqualTo(comp) == true)
  }

  @Test func severityLevelRuleInitsWithConfigArray() {
    let config = [17, 7] as Any
    let rule = try? RuleWithLevelsMock(configuration: config)
    var comp = RuleWithLevelsMock()
    comp.configuration.warning = 17
    comp.configuration.error = 7
    #expect(rule?.isEqualTo(comp) == true)
  }

  @Test func severityLevelRuleInitsWithSingleValueConfigArray() {
    let config = [17] as Any
    let rule = try? RuleWithLevelsMock(configuration: config)
    var comp = RuleWithLevelsMock()
    comp.configuration.warning = 17
    comp.configuration.error = nil
    #expect(rule?.isEqualTo(comp) == true)
  }

  @Test func severityLevelRuleInitsWithLiteral() {
    let config = 17 as Any
    let rule = try? RuleWithLevelsMock(configuration: config)
    var comp = RuleWithLevelsMock()
    comp.configuration.warning = 17
    comp.configuration.error = nil
    #expect(rule?.isEqualTo(comp) == true)
  }

  @Test func severityLevelRuleNotEqual() {
    let config = 17 as Any
    let rule = try? RuleWithLevelsMock(configuration: config)
    #expect(rule?.isEqualTo(RuleWithLevelsMock()) == false)
  }

  @Test func differentSeverityLevelRulesNotEqual() {
    #expect(!(RuleWithLevelsMock().isEqualTo(RuleWithLevelsMock2())))
  }
}
