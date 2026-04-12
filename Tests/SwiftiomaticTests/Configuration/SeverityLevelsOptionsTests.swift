import Testing

@testable import SwiftiomaticKit
@testable import SwiftiomaticSyntax

private struct MockSeverityLevelsRule: Rule {
  static let id = "test_severity_levels"
  static let name = ""
  static let summary = ""

  var options = SeverityLevelsConfiguration<Self>(warning: 12, error: nil)

  func validate(file _: SwiftSource) -> [RuleViolation] {
    []
  }
}

@Suite(.rulesRegistered) struct SeverityLevelsConfigurationTests {
  @Test func initializationWithWarningOnly() {
    let config = SeverityLevelsConfiguration<MockSeverityLevelsRule>(warning: 10)
    #expect(config.warning == 10)
    #expect(config.error == nil)

    let params = config.params
    #expect(params.count == 1)
    #expect(params[0].severity == .warning)
    #expect(params[0].value == 10)
  }

  @Test func initializationWithWarningAndError() {
    let config = SeverityLevelsConfiguration<MockSeverityLevelsRule>(warning: 10, error: 20)
    #expect(config.warning == 10)
    #expect(config.error == 20)

    let params = config.params
    #expect(params.count == 2)
    #expect(params[0].severity == .error)
    #expect(params[0].value == 20)
    #expect(params[1].severity == .warning)
    #expect(params[1].value == 10)
  }

  @Test func applyConfigurationWithSingleElementArray() throws {
    var config = SeverityLevelsConfiguration<MockSeverityLevelsRule>(warning: 0, error: 0)

    try config.apply(configuration: ["_values": [15]])

    #expect(config.warning == 15)
    #expect(config.error == nil)
  }

  @Test func applyConfigurationWithTwoElementArray() throws {
    var config = SeverityLevelsConfiguration<MockSeverityLevelsRule>(warning: 0, error: 0)

    try config.apply(configuration: ["_values": [10, 25]])

    #expect(config.warning == 10)
    #expect(config.error == 25)
  }

  @Test func applyConfigurationWithMultipleElementArray() throws {
    var config = SeverityLevelsConfiguration<MockSeverityLevelsRule>(warning: 0, error: 0)

    try config.apply(configuration: ["_values": [10, 25, 50]])

    #expect(config.warning == 10)
    #expect(config.error == 25)  // Only first two elements are used
  }

  @Test func applyConfigurationWithEmptyArray() throws {
    var config = SeverityLevelsConfiguration<MockSeverityLevelsRule>(warning: 12, error: nil)

    // Empty _values array is silently ignored (no recognized keys to apply)
    try config.apply(configuration: ["_values": [] as [Int]])
    #expect(config.warning == 12)  // unchanged
    #expect(config.error == nil)  // unchanged
  }

  @Test func applyConfigurationWithInvalidArrayType() throws {
    var config = SeverityLevelsConfiguration<MockSeverityLevelsRule>(warning: 12, error: nil)

    // Non-Int _values array fails the as? [Int] cast; silently ignored
    try config.apply(configuration: ["_values": ["invalid"]])
    #expect(config.warning == 12)  // unchanged
    #expect(config.error == nil)  // unchanged
  }

  @Test func applyConfigurationWithWarningOnlyDictionary() throws {
    var config = SeverityLevelsConfiguration<MockSeverityLevelsRule>(warning: 0, error: 0)

    try config.apply(configuration: ["warning": 15])

    #expect(config.warning == 15)
    #expect(config.error == nil)
  }

  @Test func applyConfigurationWithWarningAndErrorDictionary() throws {
    var config = SeverityLevelsConfiguration<MockSeverityLevelsRule>(warning: 0, error: 0)

    try config.apply(configuration: ["warning": 10, "error": 25])

    #expect(config.warning == 10)
    #expect(config.error == 25)
  }

  @Test func applyConfigurationWithErrorOnlyDictionary() throws {
    var config = SeverityLevelsConfiguration<MockSeverityLevelsRule>(warning: 12, error: nil)

    try config.apply(configuration: ["error": 25])

    #expect(config.warning == 12)  // Should remain unchanged
    #expect(config.error == 25)
  }

  @Test func applyConfigurationWithNilErrorDictionary() throws {
    var config = SeverityLevelsConfiguration<MockSeverityLevelsRule>(warning: 10, error: 20)

    // Specifying warning without error causes error to be set to nil
    try config.apply(configuration: ["warning": 10])

    #expect(config.warning == 10)
    #expect(config.error == nil)
  }

  @Test func applyConfigurationWithWarningSetToNilError() throws {
    var config = SeverityLevelsConfiguration<MockSeverityLevelsRule>(warning: 10, error: 20)

    try config.apply(configuration: ["warning": 15])

    #expect(config.warning == 15)
    #expect(config.error == nil)  // Should be set to nil when warning is specified without error
  }

  @Test func applyConfigurationWithInvalidWarningType() {
    var config = SeverityLevelsConfiguration<MockSeverityLevelsRule>(warning: 12, error: nil)

    #expect(throws: SwiftiomaticError.invalidConfiguration(ruleID: MockSeverityLevelsRule.identifier)) {
      try config.apply(configuration: ["warning": "invalid"])
    }
  }

  @Test func applyConfigurationWithInvalidErrorType() {
    var config = SeverityLevelsConfiguration<MockSeverityLevelsRule>(warning: 12, error: nil)

    #expect(throws: SwiftiomaticError.invalidConfiguration(ruleID: MockSeverityLevelsRule.identifier)) {
      try config.apply(configuration: ["error": "invalid"])
    }
  }

  @Test func applyConfigurationWithInvalidOptionsType() throws {
    var config = SeverityLevelsConfiguration<MockSeverityLevelsRule>(warning: 12, error: nil)

    // Unrecognized keys are silently ignored
    try config.apply(configuration: ["unrecognized": "invalid"])
    #expect(config.warning == 12)  // unchanged
    #expect(config.error == nil)  // unchanged
  }

  @Test func applyConfigurationWithEmptyDictionary() throws {
    var config = SeverityLevelsConfiguration<MockSeverityLevelsRule>(warning: 12, error: 15)

    try config.apply(configuration: [:] as [String: Any])

    #expect(config.warning == 12)
    #expect(config.error == 15)  // Should remain unchanged when nothing is applied
  }
}
