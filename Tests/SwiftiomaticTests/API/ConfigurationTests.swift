@testable import ConfigurationKit
import Foundation
@testable import SwiftiomaticKit
import Testing

@Suite
struct ConfigurationTests {
  @Test func defaultConfigurationIsSameAsEmptyDecode() throws {
    let defaultInitConfig = Configuration()

    let emptyDictionaryData = "{}\n".data(using: .utf8)!
    let jsonDecoder = JSONDecoder()
    jsonDecoder.allowsJSON5 = true
    let emptyJSONConfig =
      try jsonDecoder.decode(Configuration.self, from: emptyDictionaryData)

    #expect(defaultInitConfig == emptyJSONConfig)
  }

  @Test func missingConfigurationFile() {
    let path = "/test.swift"
    #expect(Configuration.url(forConfigurationFileApplyingTo: URL(fileURLWithPath: path)) == nil)
  }

  @Test func missingConfigurationFileInSubdirectory() {
    let path = "/whatever/test.swift"
    #expect(Configuration.url(forConfigurationFileApplyingTo: URL(fileURLWithPath: path)) == nil)
  }

  @Test func decodingReflowMultilineStringLiterals() throws {
    let testCases: [String: MultilineStringReflowBehavior] = [
      "never": .never,
      "always": .always,
      "onlyLinesOverLength": .onlyLinesOverLength,
    ]

    for (jsonString, expectedBehavior) in testCases {
      let jsonData = """
        {
          "reflowMultilineStringLiterals": "\(jsonString)"
        }
        """.data(using: .utf8)!

      let config = try JSONDecoder().decode(Configuration.self, from: jsonData)
      #expect(config[ReflowMultilineStringLiterals.self] == expectedBehavior)
    }
  }

  // MARK: - Settings

  @Test func rootLevelSettings() throws {
    let jsonData = """
      {
        "lineBreaks": {
          "lineLength": 120
        },
        "indentation": {
          "unit": { "spaces": 4 }
        },
        "tabWidth": 4
      }
      """.data(using: .utf8)!

    let config = try JSONDecoder().decode(Configuration.self, from: jsonData)
    #expect(config[LineLength.self] == 120)
    #expect(config[IndentationSetting.self] == .spaces(4))
    #expect(config[TabWidth.self] == 4)
    #expect(config[MaximumBlankLines.self] == 1)
  }

  // MARK: - Rules

  @Test func ruleLintValue() throws {
    let jsonData = """
      {
        "sort": {
          "sortImports": { "lint": "no" }
        }
      }
      """.data(using: .utf8)!

    let config = try JSONDecoder().decode(Configuration.self, from: jsonData)
    #expect(config[SortImports.self].lint == .no)
    #expect(config[SortImports.self].rewrite == true)
  }

  @Test func ruleDisabled() throws {
    let jsonData = """
      {
        "sort": {
          "sortImports": { "rewrite": false, "lint": "no" }
        }
      }
      """.data(using: .utf8)!

    let config = try JSONDecoder().decode(Configuration.self, from: jsonData)
    #expect(config[SortImports.self].rewrite == false)
    #expect(config[SortImports.self].lint == .no)
    #expect(config[SortImports.self].isActive == false)
  }

  @Test func ruleWarnAndError() throws {
    let jsonData = """
      {
        "redundancies": {
          "semicolons": { "lint": "warn" },
          "dropRedundantSelf": { "lint": "error" }
        }
      }
      """.data(using: .utf8)!

    let config = try JSONDecoder().decode(Configuration.self, from: jsonData)
    #expect(config[DropSemicolons.self].lint == .warn)
    #expect(config[DropSemicolons.self].rewrite == true)
    #expect(config[DropRedundantSelf.self].lint == .error)
  }

  @Test func lintSeverityValues() {
    #expect(Lint.warn.isActive == true)
    #expect(Lint.error.isActive == true)
    #expect(Lint.no.isActive == false)
  }

  @Test func legacyNoneDecodesAsNo() throws {
    let jsonData = """
      {
        "sort": {
          "sortImports": { "lint": "none" }
        }
      }
      """.data(using: .utf8)!

    let config = try JSONDecoder().decode(Configuration.self, from: jsonData)
    #expect(config[SortImports.self].lint == .no)
  }

  // MARK: - Config groups

  @Test func groupedRules() throws {
    let jsonData = """
      {
        "blankLines": {
          "maximumBlankLines": 2,
          "insertBlankLineAfterGuard": { "lint": "warn" },
          "insertBlankLineAfterImports": { "lint": "warn" },
          "betweenChainedFunctions": { "lint": "warn" },
          "betweenImports": { "lint": "no" },
          "insertBlankLineBetweenScopes": { "lint": "warn" }
        },
        "lineBreaks": {
          "placeElseCatchOnNewLine": true,
          "breakBeforeEachArgument": true,
          "breakBeforeGenericRequirement": true,
          "breakBetweenDeclAttributes": true,
          "breakAroundMultilineChainParts": true,
          "breakAtEndOfFile": { "lint": "warn" }
        },
        "redundancies": {
          "dropRedundantSelf": { "lint": "error" },
          "dropRedundantInitCall": { "lint": "no" },
          "dropRedundantBackticks": { "lint": "warn" }
        }
      }
      """.data(using: .utf8)!

    let config = try JSONDecoder().decode(Configuration.self, from: jsonData)
    // blankLines group
    #expect(config[MaximumBlankLines.self] == 2)
    #expect(config[InsertBlankLineAfterGuard.self].lint == .warn)
    #expect(config[InsertBlankLineAfterImports.self].lint == .warn)
    #expect(config[InsertBlankLineBetweenScopes.self].lint == .warn)
    // lineBreaks group
    #expect(config[PlaceElseCatchOnNewLine.self] == true)
    #expect(config[BreakBeforeEachArgument.self] == true)
    #expect(config[BreakBeforeGenericRequirement.self] == true)
    #expect(config[BreakBetweenDeclAttributes.self] == true)
    #expect(config[BreakAroundMultilineChainParts.self] == true)
    #expect(config[BreakAtEndOfFile.self].lint == .warn)
    // redundancies group
    #expect(config[DropRedundantSelf.self].lint == .error)
    #expect(config[DropRedundantInitCall.self].lint == .no)
    #expect(config[DropRedundantBackticks.self].lint == .warn)
  }

  // MARK: - Key derivation

  @Test(arguments: [
    ("BlankLines", "blankLines"),
    ("UseURLMacroForURLLiterals", "useURLMacroForURLLiterals"),
    ("RequireASCIIIdentifiers", "requireASCIIIdentifiers"),
    ("HTTPHeader", "httpHeader"),
    ("SortImports", "sortImports"),
    ("URL", "url"),
    ("A", "a"),
  ])
  func configurationKeyDerivation(typeName: String, expected: String) {
    #expect(configurationKey(forTypeName: typeName) == expected)
  }

  // MARK: - Dump and round-trip

  @Test func roundTripEncodeDecode() throws {
    let config = Configuration()
    let data = try JSONEncoder().encode(config)
    let decoded = try JSONDecoder().decode(Configuration.self, from: data)
    #expect(config == decoded)
  }

  // MARK: - Equality

  @Test func equalityDetectsLayoutSettingDifference() {
    var a = Configuration()
    var b = Configuration()
    #expect(a == b)
    a[LineLength.self] = 80
    b[LineLength.self] = 120
    #expect(a != b)
    b[LineLength.self] = 80
    #expect(a == b)
  }

  @Test func equalityDetectsRuleValueDifference() {
    var a = Configuration()
    var b = Configuration()
    #expect(a == b)
    var ruleValue = a[DropSemicolons.self]
    ruleValue.lint = .error
    a[DropSemicolons.self] = ruleValue
    #expect(a != b)
    b[DropSemicolons.self] = ruleValue
    #expect(a == b)
  }
}
