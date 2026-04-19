//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//
import Foundation
import SwiftiomaticKit
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

  @Test func configurationWithComments() throws {
    let expected = Configuration()

    let jsonData = """
      {
          // Indicates the configuration schema version.
          "version": 4,
      }
      """.data(using: .utf8)!

    let jsonDecoder = JSONDecoder()
    jsonDecoder.allowsJSON5 = true
    let config = try jsonDecoder.decode(Configuration.self, from: jsonData)
    #expect(config == expected)
  }

  // MARK: - Settings

  @Test func rootLevelSettings() throws {
    let jsonData = """
      {
        "lineLength": 120,
        "indentation": { "spaces": 4 },
        "tabWidth": 4
      }
      """.data(using: .utf8)!

    let config = try JSONDecoder().decode(Configuration.self, from: jsonData)
    #expect(config[LineLength.self] == 120)
    #expect(config[IndentationSetting.self] == .spaces(4))
    #expect(config[TabWidth.self] == 4)
    // Unspecified settings use defaults.
    #expect(config[MaximumBlankLines.self] == 1)
  }

  // MARK: - Rules

  @Test func ruleModeStringValue() throws {
    let jsonData = """
      {
        "SortImports": "off"
      }
      """.data(using: .utf8)!

    let config = try JSONDecoder().decode(Configuration.self, from: jsonData)
    #expect(config.rules["SortImports"] == .off)
    // Config struct should have defaults since no options were provided.
    #expect(config[SortImportsConfiguration.self].shouldGroupImports == true)
    #expect(config[SortImportsConfiguration.self].includeConditionalImports == false)
  }

  @Test func ruleObjectValue() throws {
    let jsonData = """
      {
        "SortImports": {
          "mode": "warn",
          "includeConditionalImports": true
        }
      }
      """.data(using: .utf8)!

    let config = try JSONDecoder().decode(Configuration.self, from: jsonData)
    #expect(config.rules["SortImports"] == .warning)
    #expect(config[SortImportsConfiguration.self].includeConditionalImports == true)
    #expect(config[SortImportsConfiguration.self].shouldGroupImports == true)
  }

  @Test func ruleObjectDefaultsMode() throws {
    let jsonData = """
      {
        "CapitalizeAcronyms": {
          "words": ["ID", "URL"]
        }
      }
      """.data(using: .utf8)!

    let config = try JSONDecoder().decode(Configuration.self, from: jsonData)
    #expect(config.rules["CapitalizeAcronyms"] == .warning)
    #expect(config[AcronymsConfiguration.self].words == ["ID", "URL"])
  }

  @Test func rulesMixedModeAndObject() throws {
    let jsonData = """
      {
        "SortImports": { "mode": "error", "shouldGroupImports": false },
        "CapitalizeAcronyms": "off",
        "URLMacro": { "mode": "warn", "macroName": "#URL", "moduleName": "URLFoundation" }
      }
      """.data(using: .utf8)!

    let config = try JSONDecoder().decode(Configuration.self, from: jsonData)
    #expect(config.rules["SortImports"] == .error)
    #expect(config[SortImportsConfiguration.self].shouldGroupImports == false)
    #expect(config.rules["CapitalizeAcronyms"] == .off)
    #expect(config.rules["URLMacro"] == .warning)
    #expect(config[URLMacroConfiguration.self].macroName == "#URL")
    #expect(config[URLMacroConfiguration.self].moduleName == "URLFoundation")
  }

  // MARK: - Fix mode

  @Test func fixModeForFormatRules() throws {
    let jsonData = """
      {
        "NoSemicolons": "fix",
        "SortImports": { "mode": "fix", "shouldGroupImports": true }
      }
      """.data(using: .utf8)!

    let config = try JSONDecoder().decode(Configuration.self, from: jsonData)
    #expect(config.rules["NoSemicolons"] == .fix)
    #expect(config.rules["NoSemicolons"]?.shouldFix == true)
    #expect(config.rules["NoSemicolons"]?.isActive == true)
    #expect(config.rules["SortImports"] == .fix)
  }

  @Test func fixModeDiagnosticSeverity() {
    #expect(RuleHandling.fix.diagnosticSeverity == .warning)
    #expect(RuleHandling.warning.diagnosticSeverity == .warning)
    #expect(RuleHandling.error.diagnosticSeverity == .error)
  }

  // MARK: - Config groups

  @Test func allRuleConfigsAndGroups() throws {
    let jsonData = """
      {
        "FileScopedDeclarationPrivacy": { "mode": "warn", "accessLevel": "fileprivate" },
        "NoAssignmentInExpressions": { "mode": "warn", "allowedFunctions": ["foo"] },
        "SortImports": { "mode": "error", "includeConditionalImports": true, "shouldGroupImports": false },
        "CapitalizeAcronyms": { "mode": "warn", "words": ["ID"] },
        "NoExtensionAccessLevel": { "mode": "warn", "placement": "onExtension" },
        "PatternLetPlacement": { "mode": "warn", "placement": "outerPattern" },
        "URLMacro": { "mode": "warn", "macroName": "#URL", "moduleName": "M" },
        "FileHeader": { "mode": "warn", "text": "// Header" },
        "blankLines": {
          "maximumBlankLines": 2,
          "blankLinesAfterGuardStatements": "warn",
          "blankLinesAfterImports": "warn",
          "blankLinesBetweenChainedFunctions": "warn",
          "blankLinesBetweenImports": "off",
          "blankLinesBetweenScopes": "warn"
        },
        "lineBreaks": {
          "beforeControlFlowKeywords": true,
          "beforeEachArgument": true,
          "beforeEachGenericRequirement": true,
          "betweenDeclarationAttributes": true,
          "aroundMultilineExpressionChainComponents": true,
          "ensureLineBreakAtEOF": "warn"
        },
        "redundancies": {
          "redundantSelf": "error",
          "redundantInit": "off",
          "redundantBackticks": "warn"
        }
      }
      """.data(using: .utf8)!

    let config = try JSONDecoder().decode(Configuration.self, from: jsonData)
    #expect(config[FileScopedDeclarationPrivacyConfiguration.self].accessLevel == .fileprivate)
    #expect(config[NoAssignmentInExpressionsConfiguration.self].allowedFunctions == ["foo"])
    #expect(config[SortImportsConfiguration.self].includeConditionalImports == true)
    #expect(config[SortImportsConfiguration.self].shouldGroupImports == false)
    #expect(config[AcronymsConfiguration.self].words == ["ID"])
    #expect(config[ExtensionAccessControlConfiguration.self].placement == .onExtension)
    #expect(config[PatternLetConfiguration.self].placement == .outerPattern)
    #expect(config[URLMacroConfiguration.self].macroName == "#URL")
    #expect(config[URLMacroConfiguration.self].moduleName == "M")
    #expect(config[FileHeaderConfiguration.self].text == "// Header")
    // blankLines group
    #expect(config[MaximumBlankLines.self] == 2)
    #expect(config.rules["blankLinesAfterGuardStatements"] == .warning)
    #expect(config.rules["blankLinesAfterImports"] == .warning)
    #expect(config.rules["blankLinesBetweenChainedFunctions"] == .warning)
    #expect(config.rules["blankLinesBetweenImports"] == .off)
    #expect(config.rules["blankLinesBetweenScopes"] == .warning)
    // lineBreaks group
    #expect(config[BeforeControlFlowKeywords.self] == true)
    #expect(config[BeforeEachArgument.self] == true)
    #expect(config[BeforeEachGenericRequirement.self] == true)
    #expect(config[BetweenDeclarationAttributes.self] == true)
    #expect(config[AroundMultilineExpressionChainComponents.self] == true)
    #expect(config.rules["ensureLineBreakAtEOF"] == .warning)
    // redundancies group
    #expect(config.rules["redundantSelf"] == .error)
    #expect(config.rules["redundantInit"] == .off)
    #expect(config.rules["redundantBackticks"] == .warning)
  }

  // MARK: - All mode values

  @Test func allModeValues() throws {
    let jsonData = """
      {
        "NoSemicolons": "error",
        "RedundantSelf": "warn",
        "CapitalizeAcronyms": "off",
        "SortImports": "fix"
      }
      """.data(using: .utf8)!

    let config = try JSONDecoder().decode(Configuration.self, from: jsonData)
    #expect(config.rules["NoSemicolons"] == .error)
    #expect(config.rules["RedundantSelf"] == .warning)
    #expect(config.rules["CapitalizeAcronyms"] == .off)
    #expect(config.rules["SortImports"] == .fix)
  }

  @Test func errorModeObjectForm() throws {
    let jsonData = """
      {
        "FileScopedDeclarationPrivacy": {
          "mode": "error",
          "accessLevel": "private"
        }
      }
      """.data(using: .utf8)!

    let config = try JSONDecoder().decode(Configuration.self, from: jsonData)
    #expect(config.rules["FileScopedDeclarationPrivacy"] == .error)
    #expect(config[FileScopedDeclarationPrivacyConfiguration.self].accessLevel == .private)
  }

  // MARK: - Dump and round-trip

  @Test func dumpConfigurationEmitsV4Format() throws {
    var config = Configuration()
    config[FileScopedDeclarationPrivacyConfiguration.self].accessLevel = .fileprivate
    config.rules["FileScopedDeclarationPrivacy"] = .warning

    let json = try config.asJsonString()

    // Should contain settings and rules at root level.
    #expect(json.contains("\"lineLength\""))
    #expect(json.contains("\"FileScopedDeclarationPrivacy\""))
    #expect(json.contains("\"accessLevel\""))
    // Should NOT contain v3-style format/lint sections.
    #expect(!json.contains("\"format\""))
    #expect(!json.contains("\"lint\""))
    // Should contain groups at root level.
    #expect(json.contains("\"redundancies\""))
    #expect(json.contains("\"sort\""))
  }

  @Test func roundTripEncodeDecode() throws {
    var config = Configuration()
    config[FileScopedDeclarationPrivacyConfiguration.self].accessLevel = .fileprivate
    config.rules["FileScopedDeclarationPrivacy"] = .error
    config.rules["NoSemicolons"] = .fix

    let data = try JSONEncoder().encode(config)
    let decoded = try JSONDecoder().decode(Configuration.self, from: data)
    #expect(config == decoded)
  }
}
