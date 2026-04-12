import Foundation
import Testing

@testable import SwiftiomaticKit
@testable import SwiftiomaticSyntax

@Suite struct SwiftLintConfigParserTests {
  @Test func parseDisabledRules() throws {
    let yaml = """
      disabled_rules:
        - force_cast
        - force_try
        - line_length
      """
    let config = try SwiftLintConfigParser.parse(yaml: yaml)
    #expect(config.disabledRules == ["force_cast", "force_try", "line_length"])
  }

  @Test func parseOptInRules() throws {
    let yaml = """
      opt_in_rules:
        - explicit_self
        - closure_end_indentation
      """
    let config = try SwiftLintConfigParser.parse(yaml: yaml)
    #expect(config.optInRules == ["explicit_self", "closure_end_indentation"])
  }

  @Test func parseOnlyRules() throws {
    let yaml = """
      only_rules:
        - force_cast
        - trailing_whitespace
      """
    let config = try SwiftLintConfigParser.parse(yaml: yaml)
    #expect(config.onlyRules == ["force_cast", "trailing_whitespace"])
  }

  @Test func parseIncludedExcluded() throws {
    let yaml = """
      included:
        - Sources
        - Tests
      excluded:
        - Pods
        - Carthage
      """
    let config = try SwiftLintConfigParser.parse(yaml: yaml)
    #expect(config.includedPaths == ["Sources", "Tests"])
    #expect(config.excludedPaths == ["Pods", "Carthage"])
  }

  @Test func parsePerRuleConfig() throws {
    let yaml = """
      line_length:
        warning: 120
        error: 200
      identifier_name:
        min_length: 2
      """
    let config = try SwiftLintConfigParser.parse(yaml: yaml)
    #expect(config.ruleConfigs.keys.contains("line_length"))
    #expect(config.ruleConfigs.keys.contains("identifier_name"))

    if case .dictionary(let lineLength) = config.ruleConfigs["line_length"] {
      #expect(lineLength["warning"] == .int(120))
      #expect(lineLength["error"] == .int(200))
    } else {
      Issue.record("Expected line_length config to be a dictionary")
    }
  }

  @Test func parseSeverityString() throws {
    let yaml = """
      force_cast: error
      """
    let config = try SwiftLintConfigParser.parse(yaml: yaml)
    #expect(config.ruleConfigs["force_cast"] == .string("error"))
  }

  @Test func parseAnalyzerRules() throws {
    let yaml = """
      analyzer_rules:
        - unused_import
        - unused_declaration
      """
    let config = try SwiftLintConfigParser.parse(yaml: yaml)
    #expect(config.analyzerRules == ["unused_import", "unused_declaration"])
  }

  @Test func parseEmptyYAML() throws {
    let config = try SwiftLintConfigParser.parse(yaml: "")
    #expect(config.disabledRules.isEmpty)
    #expect(config.optInRules.isEmpty)
  }

  @Test func parseRepresentativeConfig() throws {
    let yaml = """
      disabled_rules:
        - trailing_whitespace
        - force_cast
      opt_in_rules:
        - explicit_self
        - closure_end_indentation
        - sorted_imports
      excluded:
        - Pods
        - DerivedData
        - .build
      line_length:
        warning: 120
        error: 200
        ignores_comments: true
      identifier_name:
        min_length:
          warning: 2
          error: 1
        excluded:
          - id
          - db
      """
    let config = try SwiftLintConfigParser.parse(yaml: yaml)

    #expect(config.disabledRules == ["trailing_whitespace", "force_cast"])
    #expect(config.optInRules.count == 3)
    #expect(config.excludedPaths == ["Pods", "DerivedData", ".build"])
    #expect(config.ruleConfigs.keys.contains("line_length"))
    #expect(config.ruleConfigs.keys.contains("identifier_name"))
  }
}
