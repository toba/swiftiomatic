@testable import Swiftiomatic

/// A minimal ``RuleConfiguration`` for test mock rules
struct TestMockRuleConfiguration: RuleConfiguration {
  let id: String
  let name: String
  let summary: String

  init(id: String, name: String = "", summary: String = "") {
    self.id = id
    self.name = name
    self.summary = summary
  }
}

struct MockRuleConfiguration: RuleConfiguration {
  let id = "MockRule"
  let name = ""
  let summary = ""
}

struct MockRule: Rule {
  var configurationDescription: some Documentable { RuleOptionsEntry.noOptions }

  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = MockRuleConfiguration()

  static let description = RuleDescription(
    identifier: "MockRule",
    name: "",
    description: "",
  )

  init() { /* conformance for test */  }
  init(configuration _: Any) { self.init() }

  func validate(file _: SwiftSource) -> [RuleViolation] { [] }
}

struct RuleWithLevelsMockConfiguration: RuleConfiguration {
  let id = "severity_level_mock"
  let name = ""
  let summary = ""
  let deprecatedAliases: Set<String> = ["mock"]
}

struct RuleWithLevelsMock: Rule {
  var options = SeverityLevelsConfiguration<Self>(warning: 2, error: 3)

  static let configuration = RuleWithLevelsMockConfiguration()

  static let description = RuleDescription(
    identifier: "severity_level_mock",
    name: "",
    description: "",
    deprecatedAliases: ["mock"],
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
    try self.options.apply(configuration: normalized)
  }

  func validate(file _: SwiftSource) -> [RuleViolation] { [] }
}
