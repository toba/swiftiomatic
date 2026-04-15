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

/// Generates `swiftiomatic.schema.json` by encoding a `JSONSchemaNode` tree.
///
/// Rule descriptions are sourced from `RuleCollector` (extracted from DocC comments)
/// so they stay in sync with rule implementations.
@_spi(Internal) public final class ConfigurationSchemaGenerator: FileGenerator {

  let ruleCollector: RuleCollector

  public init(ruleCollector: RuleCollector) {
    self.ruleCollector = ruleCollector
  }

  public func generateContent() -> String {
    let schema = buildSchema()
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
    guard let data = try? encoder.encode(schema),
      let json = String(data: data, encoding: .utf8)
    else {
      fatalError("Failed to encode configuration schema")
    }
    return json + "\n"
  }

  private func buildSchema() -> JSONSchemaNode {
    var root = JSONSchemaNode()
    root.schema = "https://json-schema.org/draft/2020-12/schema"
    root.id = Configuration.schemaURL
    root.title = "Swiftiomatic Configuration"
    root.description = "Configuration for the sm Swift formatter and linter."
    root.type = "object"
    root.additionalProperties = false

    var p: [String: JSONSchemaNode] = [:]

    p["$schema"] = .string(description: "JSON Schema reference URL.")
    p["version"] = .integer(description: "Configuration format version.", defaultValue: 1, minimum: 1)

    // Core formatting
    p["maximumBlankLines"] = .integer(
      description: "Maximum consecutive blank lines.", defaultValue: 1, minimum: 0)
    p["lineLength"] = .integer(
      description: "Maximum line length before wrapping.", defaultValue: 100, minimum: 1)
    p["spacesBeforeEndOfLineComments"] = .integer(
      description: "Spaces before // comments.", defaultValue: 2, minimum: 0)
    p["tabWidth"] = .integer(
      description: "Tab width in spaces for indentation conversion.", defaultValue: 8, minimum: 1)

    // Indentation (oneOf)
    var indent = JSONSchemaNode()
    indent.description = "Indentation unit: exactly one of spaces or tabs."
    indent.defaultValue = .object(["spaces": .int(2)])
    var spacesVariant = JSONSchemaNode.object(
      description: "Indent with spaces.",
      properties: [
        "spaces": .integer(description: "Number of spaces per indent level.", defaultValue: 2, minimum: 1)
      ])
    spacesVariant.required = ["spaces"]
    var tabsVariant = JSONSchemaNode.object(
      description: "Indent with tabs.",
      properties: [
        "tabs": .integer(description: "Number of tabs per indent level.", defaultValue: 1, minimum: 1)
      ])
    tabsVariant.required = ["tabs"]
    indent.oneOf = [spacesVariant, tabsVariant]
    p["indentation"] = indent

    // Boolean options
    p["respectsExistingLineBreaks"] = .boolean(
      description: "Preserve discretionary line breaks.", defaultValue: true)
    p["lineBreakBeforeControlFlowKeywords"] = .boolean(
      description: "Break before else/catch after closing brace.", defaultValue: false)
    p["lineBreakBeforeEachArgument"] = .boolean(
      description: "Break before each argument when wrapping.", defaultValue: false)
    p["lineBreakBeforeEachGenericRequirement"] = .boolean(
      description: "Break before each generic requirement when wrapping.", defaultValue: false)
    p["lineBreakBetweenDeclarationAttributes"] = .boolean(
      description: "Break between adjacent attributes.", defaultValue: false)
    p["prioritizeKeepingFunctionOutputTogether"] = .boolean(
      description: "Keep return type with closing parenthesis.", defaultValue: false)
    p["indentConditionalCompilationBlocks"] = .boolean(
      description: "Indent #if/#elseif/#else blocks.", defaultValue: true)
    p["lineBreakAroundMultilineExpressionChainComponents"] = .boolean(
      description: "Break around multiline dot-chained components.", defaultValue: false)
    p["indentSwitchCaseLabels"] = .boolean(
      description: "Indent case labels relative to switch.", defaultValue: false)
    p["spacesAroundRangeFormationOperators"] = .boolean(
      description: "Force spaces around ... and ..<.", defaultValue: false)
    p["multiElementCollectionTrailingCommas"] = .boolean(
      description: "Trailing commas in multi-element collection literals.", defaultValue: true)
    p["indentBlankLines"] = .boolean(
      description: "Add indentation whitespace to blank lines.", defaultValue: false)

    // String enums
    p["multilineTrailingCommaBehavior"] = .stringEnum(
      description: "Trailing comma handling in multiline lists.",
      values: ["alwaysUsed", "neverUsed", "keptAsWritten"],
      defaultValue: "keptAsWritten")
    p["reflowMultilineStringLiterals"] = .stringEnum(
      description: "Multiline string literal reflow mode.",
      values: ["never", "onlyLinesOverLength", "always"],
      defaultValue: "never")

    // Nested config objects
    p["fileScopedDeclarationPrivacy"] = .object(
      description: "File-scoped declaration access level.",
      properties: [
        "accessLevel": .stringEnum(
          description: "Access level for file-scoped private declarations.",
          values: ["private", "fileprivate"],
          defaultValue: "private")
      ])
    p["noAssignmentInExpressions"] = .object(
      description: "NoAssignmentInExpressions rule exceptions.",
      properties: [
        "allowedFunctions": .stringArray(
          description: "Functions where embedded assignments are allowed.",
          defaultValue: ["XCTAssertNoThrow"])
      ])
    p["sortImports"] = .object(
      description: "Import sorting options.",
      properties: [
        "includeConditionalImports": .boolean(
          description: "Sort imports within #if blocks.", defaultValue: false),
        "shouldGroupImports": .boolean(
          description: "Separate imports into groups by type.", defaultValue: true),
      ])
    p["acronyms"] = .object(
      description: "Acronym capitalization options for the CapitalizeAcronyms rule.",
      properties: [
        "words": .stringArray(
          description: "Acronyms to capitalize (fully uppercased).",
          defaultValue: [
            "API", "CSS", "DNS", "FTP", "GIF", "HTML", "HTTP", "HTTPS",
            "ID", "JPEG", "JSON", "PDF", "PNG", "RGB", "RGBA",
            "SQL", "SSH", "TCP", "UDP", "URL", "UUID", "XML",
          ])
      ])
    p["extensionAccessControl"] = .object(
      description: "Extension access control modifier placement.",
      properties: [
        "placement": .stringEnum(
          description: "Where to place access control modifiers.",
          values: ["onDeclarations", "onExtension"],
          defaultValue: "onDeclarations")
      ])
    p["patternLet"] = .object(
      description: "Case pattern let/var placement.",
      properties: [
        "placement": .stringEnum(
          description: "Where to place let/var in case patterns.",
          values: ["eachBinding", "outerPattern"],
          defaultValue: "eachBinding")
      ])
    p["urlMacro"] = .object(
      description: "URL(string:)! to macro replacement.",
      properties: [
        "macroName": .string(description: "Macro name, e.g. \"#URL\". Omit to disable."),
        "moduleName": .string(description: "Module to import for the macro."),
      ])
    p["fileHeader"] = .object(
      description: "File header enforcement.",
      properties: [
        "text": .string(
          description: "Header text. Omit to disable, empty string to remove headers.")
      ])

    // Rules — descriptions sourced from RuleCollector (DocC comments on rule classes)
    var rulesProps: [String: JSONSchemaNode] = [:]
    for rule in ruleCollector.allLinters.sorted(by: { $0.typeName < $1.typeName }) {
      var desc = rule.description ?? (rule.canFormat ? "Format rule." : "Lint rule.")
      if rule.canFormat { desc += " [format]" }
      if rule.isOptIn { desc += " [opt-in]" }
      rulesProps[rule.typeName] = .boolean(description: desc, defaultValue: !rule.isOptIn)
    }
    p["rules"] = .object(
      description: "Enable or disable individual rules by name.",
      properties: rulesProps)

    root.properties = p
    return root
  }
}
