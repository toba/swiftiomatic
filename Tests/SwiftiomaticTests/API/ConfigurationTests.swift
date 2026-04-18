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
import Swiftiomatic
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
    let testCases: [String: Configuration.MultilineStringReflowBehavior] = [
      "never": .never,
      "always": .always,
      "onlyLinesOverLength": .onlyLinesOverLength,
    ]

    for (jsonString, expectedBehavior) in testCases {
      let jsonData = """
        {
          "format": {
            "reflowMultilineStringLiterals": "\(jsonString)"
          }
        }
        """.data(using: .utf8)!

      let config = try JSONDecoder().decode(Configuration.self, from: jsonData)
      #expect(config.reflowMultilineStringLiterals == expectedBehavior)
    }
  }

  @Test func configurationWithComments() throws {
    let expected = Configuration()

    let jsonData = """
      {
          // Indicates the configuration schema version.
          "version": 3,
      }
      """.data(using: .utf8)!

    let jsonDecoder = JSONDecoder()
    jsonDecoder.allowsJSON5 = true
    let config = try jsonDecoder.decode(Configuration.self, from: jsonData)
    #expect(config == expected)
  }

  // MARK: - Format section

  @Test func formatSettings() throws {
    let jsonData = """
      {
        "format": {
          "lineLength": 120,
          "indentation": { "spaces": 4 },
          "tabWidth": 4
        }
      }
      """.data(using: .utf8)!

    let config = try JSONDecoder().decode(Configuration.self, from: jsonData)
    #expect(config.lineLength == 120)
    #expect(config.indentation == .spaces(4))
    #expect(config.tabWidth == 4)
    // Unspecified settings use defaults.
    #expect(config.maximumBlankLines == 1)
  }

  @Test func formatRuleSeverityValue() throws {
    let jsonData = """
      {
        "format": {
          "SortImports": "off"
        }
      }
      """.data(using: .utf8)!

    let config = try JSONDecoder().decode(Configuration.self, from: jsonData)
    #expect(config.rules["SortImports"] == .off)
    // Config struct should have defaults since no options were provided.
    #expect(config.sortImports.shouldGroupImports == true)
    #expect(config.sortImports.includeConditionalImports == false)
  }

  @Test func formatRuleObjectValue() throws {
    let jsonData = """
      {
        "format": {
          "SortImports": {
            "severity": "warn",
            "includeConditionalImports": true
          }
        }
      }
      """.data(using: .utf8)!

    let config = try JSONDecoder().decode(Configuration.self, from: jsonData)
    #expect(config.rules["SortImports"] == .warning)
    #expect(config.sortImports.includeConditionalImports == true)
    #expect(config.sortImports.shouldGroupImports == true)
  }

  @Test func formatRuleObjectDefaultsSeverity() throws {
    let jsonData = """
      {
        "format": {
          "CapitalizeAcronyms": {
            "words": ["ID", "URL"]
          }
        }
      }
      """.data(using: .utf8)!

    let config = try JSONDecoder().decode(Configuration.self, from: jsonData)
    #expect(config.rules["CapitalizeAcronyms"] == .warning)
    #expect(config.acronyms.words == ["ID", "URL"])
  }

  @Test func formatRulesMixedSeverityAndObject() throws {
    let jsonData = """
      {
        "format": {
          "SortImports": { "severity": "error", "shouldGroupImports": false },
          "CapitalizeAcronyms": "off",
          "URLMacro": { "severity": "warn", "macroName": "#URL", "moduleName": "URLFoundation" }
        }
      }
      """.data(using: .utf8)!

    let config = try JSONDecoder().decode(Configuration.self, from: jsonData)
    #expect(config.rules["SortImports"] == .error)
    #expect(config.sortImports.shouldGroupImports == false)
    #expect(config.rules["CapitalizeAcronyms"] == .off)
    #expect(config.rules["URLMacro"] == .warning)
    #expect(config.urlMacro.macroName == "#URL")
    #expect(config.urlMacro.moduleName == "URLFoundation")
  }

  @Test func allRuleConfigsViaFormatSection() throws {
    let jsonData = """
      {
        "format": {
          "FileScopedDeclarationPrivacy": { "severity": "warn", "accessLevel": "fileprivate" },
          "NoAssignmentInExpressions": { "severity": "warn", "allowedFunctions": ["foo"] },
          "SortImports": { "severity": "error", "includeConditionalImports": true, "shouldGroupImports": false },
          "CapitalizeAcronyms": { "severity": "warn", "words": ["ID"] },
          "NoExtensionAccessLevel": { "severity": "warn", "placement": "onExtension" },
          "PatternLetPlacement": { "severity": "warn", "placement": "outerPattern" },
          "URLMacro": { "severity": "warn", "macroName": "#URL", "moduleName": "M" },
          "FileHeader": { "severity": "warn", "text": "// Header" },
          "UpdateBlankLines": {
            "severity": "warn",
            "maximumBlankLines": 2,
            "afterGuardStatements": true,
            "afterImports": true,
            "betweenChainedFunctions": true,
            "betweenImports": false,
            "betweenScopes": true
          },
          "RemoveRedundant": {
            "severity": "error",
            "self": true,
            "init": false,
            "backticks": "warn"
          }
        }
      }
      """.data(using: .utf8)!

    let config = try JSONDecoder().decode(Configuration.self, from: jsonData)
    #expect(config.fileScopedDeclarationPrivacy.accessLevel == .fileprivate)
    #expect(config.noAssignmentInExpressions.allowedFunctions == ["foo"])
    #expect(config.sortImports.includeConditionalImports == true)
    #expect(config.sortImports.shouldGroupImports == false)
    #expect(config.acronyms.words == ["ID"])
    #expect(config.extensionAccessControl.placement == .onExtension)
    #expect(config.patternLet.placement == .outerPattern)
    #expect(config.urlMacro.macroName == "#URL")
    #expect(config.urlMacro.moduleName == "M")
    #expect(config.fileHeader.text == "// Header")
    // UpdateBlankLines umbrella
    #expect(config.maximumBlankLines == 2)
    #expect(config.rules["BlankLinesAfterGuardStatements"] == .warning)
    #expect(config.rules["BlankLinesAfterImports"] == .warning)
    #expect(config.rules["BlankLinesBetweenChainedFunctions"] == .warning)
    #expect(config.rules["BlankLinesBetweenImports"] == .off)
    #expect(config.rules["BlankLinesBetweenScopes"] == .warning)
    // RemoveRedundant umbrella
    #expect(config.rules["RedundantSelf"] == .error)
    #expect(config.rules["RedundantInit"] == .off)
    #expect(config.rules["RedundantBackticks"] == .warning)
  }

  // MARK: - Lint section

  @Test func lintRules() throws {
    let jsonData = """
      {
        "lint": {
          "LowerCamelCase": "off",
          "NoBlockComments": "error"
        }
      }
      """.data(using: .utf8)!

    let config = try JSONDecoder().decode(Configuration.self, from: jsonData)
    #expect(config.rules["LowerCamelCase"] == .off)
    #expect(config.rules["NoBlockComments"] == .error)
  }

  // MARK: - Severity

  @Test func allSeverityValues() throws {
    let jsonData = """
      {
        "format": {
          "NoSemicolons": "error",
          "RedundantSelf": "warn",
          "CapitalizeAcronyms": "off"
        }
      }
      """.data(using: .utf8)!

    let config = try JSONDecoder().decode(Configuration.self, from: jsonData)
    #expect(config.rules["NoSemicolons"] == .error)
    #expect(config.rules["RedundantSelf"] == .warning)
    #expect(config.rules["CapitalizeAcronyms"] == .off)
  }

  @Test func errorSeverityObjectForm() throws {
    let jsonData = """
      {
        "format": {
          "FileScopedDeclarationPrivacy": {
            "severity": "error",
            "accessLevel": "private"
          }
        }
      }
      """.data(using: .utf8)!

    let config = try JSONDecoder().decode(Configuration.self, from: jsonData)
    #expect(config.rules["FileScopedDeclarationPrivacy"] == .error)
    #expect(config.fileScopedDeclarationPrivacy.accessLevel == .private)
  }

  // MARK: - Dump and round-trip

  @Test func dumpConfigurationEmitsV3Format() throws {
    var config = Configuration()
    config.sortImports.includeConditionalImports = true
    config.rules["SortImports"] = .warning

    let json = try config.asJsonString()

    // Should contain format and lint sections.
    #expect(json.contains("\"format\""))
    #expect(json.contains("\"lint\""))
    // Should NOT contain a top-level "rules" key.
    #expect(!json.contains("\"rules\" :"))
    // SortImports options should be inside the format section.
    #expect(json.contains("\"includeConditionalImports\""))
    #expect(json.contains("\"SortImports\""))
  }

  @Test func roundTripEncodeDecode() throws {
    var config = Configuration()
    config.sortImports.includeConditionalImports = true
    config.acronyms.words = ["ID", "URL"]
    config.rules["SortImports"] = .warning
    config.rules["CapitalizeAcronyms"] = .error

    let data = try JSONEncoder().encode(config)
    let decoded = try JSONDecoder().decode(Configuration.self, from: data)
    #expect(config == decoded)
  }
}
