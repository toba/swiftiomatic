// Adapted from SwiftLint 0.63.2 CoreTests (MIT license)

import Testing

@testable import Swiftiomatic

@Suite struct RegexConfigurationTests {
  init() { RuleRegistry.registerAllRulesOnce() }

  @Test func shouldValidateIsTrueByDefault() {
    let config = RegexConfiguration<MockRule>(identifier: "example")
    #expect(config.shouldValidate(filePath: "App/file.swift"))
  }

  @Test func shouldValidateWithSingleExluded() throws {
    var config = RegexConfiguration<MockRule>(identifier: "example")
    try config.apply(configuration: [
      "regex": "try!",
      "excluded": "Tests/.*\\.swift",
    ])

    #expect(!(config.shouldValidate(filePath: "Tests/file.swift")))
    #expect(config.shouldValidate(filePath: "App/file.swift"))
  }

  @Test func shouldValidateWithArrayExluded() throws {
    var config = RegexConfiguration<MockRule>(identifier: "example")
    try config.apply(configuration: [
      "regex": "try!",
      "excluded": [
        "^Tests/.*\\.swift",
        "^MyFramework/Tests/.*\\.swift",
      ] as Any,
    ])

    #expect(!(config.shouldValidate(filePath: "Tests/file.swift")))
    #expect(!(config.shouldValidate(filePath: "MyFramework/Tests/file.swift")))
    #expect(config.shouldValidate(filePath: "App/file.swift"))
  }

  @Test func shouldValidateWithSingleIncluded() throws {
    var config = RegexConfiguration<MockRule>(identifier: "example")
    try config.apply(configuration: [
      "regex": "try!",
      "included": "App/.*\\.swift",
    ])

    #expect(!(config.shouldValidate(filePath: "Tests/file.swift")))
    #expect(!(config.shouldValidate(filePath: "MyFramework/Tests/file.swift")))
    #expect(config.shouldValidate(filePath: "App/file.swift"))
  }

  @Test func shouldValidateWithArrayIncluded() throws {
    var config = RegexConfiguration<MockRule>(identifier: "example")
    try config.apply(configuration: [
      "regex": "try!",
      "included": [
        "App/.*\\.swift",
        "MyFramework/.*\\.swift",
      ] as Any,
    ])

    #expect(!(config.shouldValidate(filePath: "Tests/file.swift")))
    #expect(config.shouldValidate(filePath: "App/file.swift"))
    #expect(config.shouldValidate(filePath: "MyFramework/file.swift"))
  }

  @Test func shouldValidateWithIncludedAndExcluded() throws {
    var config = RegexConfiguration<MockRule>(identifier: "example")
    try config.apply(configuration: [
      "regex": "try!",
      "included": [
        "App/.*\\.swift",
        "MyFramework/.*\\.swift",
      ] as Any,
      "excluded": [
        "Tests/.*\\.swift",
        "App/Fixtures/.*\\.swift",
      ] as Any,
    ])

    #expect(config.shouldValidate(filePath: "App/file.swift"))
    #expect(config.shouldValidate(filePath: "MyFramework/file.swift"))

    #expect(!(config.shouldValidate(filePath: "App/Fixtures/file.swift")))
    #expect(!(config.shouldValidate(filePath: "Tests/file.swift")))
    #expect(!(config.shouldValidate(filePath: "MyFramework/Tests/file.swift")))
  }
}
