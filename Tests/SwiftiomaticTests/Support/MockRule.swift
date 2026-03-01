@testable import Swiftiomatic

struct MockRule: Rule {
  var configurationDescription: some Documentable { RuleOptionsEntry.noOptions }

  var options = SeverityConfiguration<Self>(.warning)

  static let description = RuleDescription(
    identifier: "MockRule",
    name: "",
    description: "",
  )

  init() { /* conformance for test */  }
  init(configuration _: Any) { self.init() }

  func validate(file _: SwiftSource) -> [RuleViolation] { [] }
}

struct RuleWithLevelsMock: Rule {
  var options = SeverityLevelsConfiguration<Self>(warning: 2, error: 3)

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
