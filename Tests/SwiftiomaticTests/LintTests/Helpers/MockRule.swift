// Adapted from SwiftLint 0.63.2 (MIT license)

@testable import Swiftiomatic

struct MockRule: Rule {
  var configurationDescription: some Documentable { RuleConfigurationOption.noOptions }

  var configuration = SeverityConfiguration<Self>(.warning)

  static let description = RuleDescription(
    identifier: "MockRule",
    name: "",
    description: "",
    kind: .style
  )

  init() { /* conformance for test */  }
  init(configuration _: Any) { self.init() }

  func validate(file _: SwiftLintFile) -> [StyleViolation] { [] }
}

struct RuleWithLevelsMock: Rule {
  var configuration = SeverityLevelsConfiguration<Self>(warning: 2, error: 3)

  static let description = RuleDescription(
    identifier: "severity_level_mock",
    name: "",
    description: "",
    kind: .style,
    deprecatedAliases: ["mock"])

  init() { /* conformance for test */  }
  init(configuration: Any) throws {
    self.init()
    try self.configuration.apply(configuration: configuration)
  }

  func validate(file _: SwiftLintFile) -> [StyleViolation] { [] }
}
