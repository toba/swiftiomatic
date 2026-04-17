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

  @Test func formatRuleBoolValue() throws {
    let jsonData = """
      {
        "format": {
          "SortImports": false
        }
      }
      """.data(using: .utf8)!

    let config = try JSONDecoder().decode(Configuration.self, from: jsonData)
    #expect(config.rules["SortImports"] == false)
    // Config struct should have defaults since no options were provided.
    #expect(config.sortImports.shouldGroupImports == true)
    #expect(config.sortImports.includeConditionalImports == false)
  }

  @Test func formatRuleObjectValue() throws {
    let jsonData = """
      {
        "format": {
          "SortImports": {
            "enabled": true,
            "includeConditionalImports": true
          }
        }
      }
      """.data(using: .utf8)!

    let config = try JSONDecoder().decode(Configuration.self, from: jsonData)
    #expect(config.rules["SortImports"] == true)
    #expect(config.sortImports.includeConditionalImports == true)
    #expect(config.sortImports.shouldGroupImports == true)
  }

  @Test func formatRuleObjectDefaultsEnabled() throws {
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
    #expect(config.rules["CapitalizeAcronyms"] == true)
    #expect(config.acronyms.words == ["ID", "URL"])
  }

  @Test func formatRulesMixedBoolAndObject() throws {
    let jsonData = """
      {
        "format": {
          "SortImports": { "enabled": true, "shouldGroupImports": false },
          "CapitalizeAcronyms": false,
          "URLMacro": { "enabled": true, "macroName": "#URL", "moduleName": "URLFoundation" }
        }
      }
      """.data(using: .utf8)!

    let config = try JSONDecoder().decode(Configuration.self, from: jsonData)
    #expect(config.rules["SortImports"] == true)
    #expect(config.sortImports.shouldGroupImports == false)
    #expect(config.rules["CapitalizeAcronyms"] == false)
    #expect(config.rules["URLMacro"] == true)
    #expect(config.urlMacro.macroName == "#URL")
    #expect(config.urlMacro.moduleName == "URLFoundation")
  }

  @Test func allRuleConfigsViaFormatSection() throws {
    let jsonData = """
      {
        "format": {
          "FileScopedDeclarationPrivacy": { "enabled": true, "accessLevel": "fileprivate" },
          "NoAssignmentInExpressions": { "enabled": true, "allowedFunctions": ["foo"] },
          "SortImports": { "enabled": true, "includeConditionalImports": true, "shouldGroupImports": false },
          "CapitalizeAcronyms": { "enabled": true, "words": ["ID"] },
          "NoExtensionAccessLevel": { "enabled": true, "placement": "onExtension" },
          "PatternLetPlacement": { "enabled": true, "placement": "outerPattern" },
          "URLMacro": { "enabled": true, "macroName": "#URL", "moduleName": "M" },
          "FileHeader": { "enabled": true, "text": "// Header" }
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
  }

  // MARK: - Lint section

  @Test func lintRules() throws {
    let jsonData = """
      {
        "lint": {
          "LowerCamelCase": false,
          "NoBlockComments": true
        }
      }
      """.data(using: .utf8)!

    let config = try JSONDecoder().decode(Configuration.self, from: jsonData)
    #expect(config.rules["LowerCamelCase"] == false)
    #expect(config.rules["NoBlockComments"] == true)
  }

  // MARK: - Dump and round-trip

  @Test func dumpConfigurationEmitsV3Format() throws {
    var config = Configuration()
    config.sortImports.includeConditionalImports = true
    config.rules["SortImports"] = true

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
    config.rules["SortImports"] = true
    config.rules["CapitalizeAcronyms"] = true

    let data = try JSONEncoder().encode(config)
    let decoded = try JSONDecoder().decode(Configuration.self, from: data)
    #expect(config == decoded)
  }
}
