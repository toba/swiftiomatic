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
    // Since we don't use the synthesized `init(from: Decoder)` and allow fields
    // to be missing, we provide defaults there as well as in the property
    // declarations themselves. This test ensures that creating a default-
    // initialized `Configuration` is identical to decoding one from an empty
    // JSON input, which verifies that those defaults are always in sync.
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

  @Test func decodingReflowMultilineStringLiteralsAsString() throws {
    let testCases: [String: Configuration.MultilineStringReflowBehavior] = [
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

      let jsonDecoder = JSONDecoder()
      jsonDecoder.allowsJSON5 = true
      let config = try jsonDecoder.decode(Configuration.self, from: jsonData)
      #expect(config.reflowMultilineStringLiterals == expectedBehavior)
    }
  }

  @Test func decodingReflowMultilineStringLiteralsAsObject() throws {
    let testCases: [String: Configuration.MultilineStringReflowBehavior] = [
      "{ \"never\": {} }": .never,
      "{ \"always\": {} }": .always,
      "{ \"onlyLinesOverLength\": {} }": .onlyLinesOverLength,
    ]

    for (jsonString, expectedBehavior) in testCases {
      let jsonData = """
        {
            "reflowMultilineStringLiterals": \(jsonString)
        }
        """.data(using: .utf8)!

      let jsonDecoder = JSONDecoder()
      jsonDecoder.allowsJSON5 = true
      let config = try jsonDecoder.decode(Configuration.self, from: jsonData)
      #expect(config.reflowMultilineStringLiterals == expectedBehavior)
    }
  }

  @Test func configurationWithComments() throws {
    let expected = Configuration()

    let jsonData = """
      {
          // Indicates the configuration schema version.
          "version": 2,
      }
      """.data(using: .utf8)!

    let jsonDecoder = JSONDecoder()
    jsonDecoder.allowsJSON5 = true
    let config = try jsonDecoder.decode(Configuration.self, from: jsonData)
    #expect(config == expected)
  }

  // MARK: - Unified rules dict

  @Test func unifiedRulesBoolValue() throws {
    let jsonData = """
      {
        "rules": {
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

  @Test func unifiedRulesObjectValue() throws {
    let jsonData = """
      {
        "rules": {
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
    // Omitted options should use defaults.
    #expect(config.sortImports.shouldGroupImports == true)
  }

  @Test func unifiedRulesObjectDefaultsEnabled() throws {
    // When "enabled" is omitted from the object, it defaults to true.
    let jsonData = """
      {
        "rules": {
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

  @Test func unifiedRulesMixedBoolAndObject() throws {
    let jsonData = """
      {
        "rules": {
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

  @Test func backwardCompatTopLevelKeys() throws {
    // Old format: rule options at the top level.
    let jsonData = """
      {
        "sortImports": { "includeConditionalImports": true },
        "rules": { "SortImports": true }
      }
      """.data(using: .utf8)!

    let config = try JSONDecoder().decode(Configuration.self, from: jsonData)
    #expect(config.sortImports.includeConditionalImports == true)
    #expect(config.rules["SortImports"] == true)
  }

  @Test func unifiedRulesTakePrecedenceOverTopLevel() throws {
    // When both the unified rules dict and old top-level key are present,
    // the rules dict should win.
    let jsonData = """
      {
        "sortImports": { "includeConditionalImports": false },
        "rules": {
          "SortImports": { "enabled": true, "includeConditionalImports": true }
        }
      }
      """.data(using: .utf8)!

    let config = try JSONDecoder().decode(Configuration.self, from: jsonData)
    #expect(config.sortImports.includeConditionalImports == true)
  }

  @Test func allRuleConfigsViaUnifiedDict() throws {
    let jsonData = """
      {
        "rules": {
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

  @Test func dumpConfigurationEmitsUnifiedFormat() throws {
    var config = Configuration()
    config.sortImports.includeConditionalImports = true
    config.rules["SortImports"] = true

    let json = try config.asJsonString()

    // Should NOT contain top-level "sortImports" key.
    #expect(!json.contains("\"sortImports\" :"))
    // Should contain the option inside the rules dict.
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
