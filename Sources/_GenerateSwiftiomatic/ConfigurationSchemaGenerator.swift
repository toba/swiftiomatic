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

/// Generates `schema.json` by encoding a `JSONSchemaNode` tree.
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
        p["version"] = .integer(
            description: "Configuration format version.",
            defaultValue: 3,
            minimum: 1
        )

        // Build the `format` section: settings + format rules.
        var formatProps = formatSettingsSchema()

        let formatRules = ruleCollector.allLinters
            .filter { $0.canFormat }
            .sorted(by: { $0.typeName < $1.typeName })
        for rule in formatRules {
            formatProps[rule.typeName] = ruleSchemaNode(for: rule)
        }
        p["format"] = .object(
            description: "Formatting settings and format rules. Settings control the pretty-printer; rules are severity strings ('warn', 'error', 'off') or objects with 'severity' plus rule-specific options.",
            properties: formatProps
        )

        // Build the `lint` section: lint rules only.
        var lintProps: [String: JSONSchemaNode] = [:]
        let lintRules = ruleCollector.allLinters
            .filter { !$0.canFormat }
            .sorted(by: { $0.typeName < $1.typeName })
        for rule in lintRules {
            lintProps[rule.typeName] = ruleSchemaNode(for: rule)
        }
        p["lint"] = .object(
            description: "Lint rules. Each value is a severity: 'warn', 'error', or 'off'.",
            properties: lintProps
        )

        root.properties = p
        return root
    }

    private func ruleSchemaNode(for rule: RuleCollector.DetectedRule) -> JSONSchemaNode {
        var desc = rule.description ?? (rule.canFormat ? "Format rule." : "Lint rule.")
        if rule.isOptIn { desc += " [opt-in]" }

        let severityVariant = JSONSchemaNode.stringEnum(
            description: desc,
            values: ["warn", "error", "off"],
            defaultValue: rule.isOptIn ? "off" : "warn"
        )

        if let optionsSchema = ruleOptionsSchema(for: rule.typeName, isOptIn: rule.isOptIn) {
            var node = JSONSchemaNode()
            node.description = desc
            node.oneOf = [severityVariant, optionsSchema]
            return node
        } else {
            return severityVariant
        }
    }

    private func formatSettingsSchema() -> [String: JSONSchemaNode] {
        var p: [String: JSONSchemaNode] = [:]

        p["maximumBlankLines"] = .integer(description: "Maximum consecutive blank lines.", defaultValue: 1, minimum: 0)
        p["lineLength"] = .integer(description: "Maximum line length before wrapping.", defaultValue: 100, minimum: 1)
        p["spacesBeforeEndOfLineComments"] = .integer(description: "Spaces before // comments.", defaultValue: 2, minimum: 0)
        p["tabWidth"] = .integer(description: "Tab width in spaces for indentation conversion.", defaultValue: 8, minimum: 1)

        var indent = JSONSchemaNode()
        indent.description = "Indentation unit: exactly one of spaces or tabs."
        indent.defaultValue = .object(["spaces": .int(2)])
        var spacesVariant = JSONSchemaNode.object(
            description: "Indent with spaces.",
            properties: ["spaces": .integer(description: "Number of spaces per indent level.", defaultValue: 2, minimum: 1)]
        )
        spacesVariant.required = ["spaces"]
        var tabsVariant = JSONSchemaNode.object(
            description: "Indent with tabs.",
            properties: ["tabs": .integer(description: "Number of tabs per indent level.", defaultValue: 1, minimum: 1)]
        )
        tabsVariant.required = ["tabs"]
        indent.oneOf = [spacesVariant, tabsVariant]
        p["indentation"] = indent

        p["respectsExistingLineBreaks"] = .boolean(description: "Preserve discretionary line breaks.", defaultValue: true)
        p["lineBreakBeforeControlFlowKeywords"] = .boolean(description: "Break before else/catch after closing brace.", defaultValue: false)
        p["lineBreakBeforeEachArgument"] = .boolean(description: "Break before each argument when wrapping.", defaultValue: false)
        p["lineBreakBeforeEachGenericRequirement"] = .boolean(description: "Break before each generic requirement when wrapping.", defaultValue: false)
        p["lineBreakBetweenDeclarationAttributes"] = .boolean(description: "Break between adjacent attributes.", defaultValue: false)
        p["prioritizeKeepingFunctionOutputTogether"] = .boolean(description: "Keep return type with closing parenthesis.", defaultValue: false)
        p["indentConditionalCompilationBlocks"] = .boolean(description: "Indent #if/#elseif/#else blocks.", defaultValue: true)
        p["lineBreakAroundMultilineExpressionChainComponents"] = .boolean(description: "Break around multiline dot-chained components.", defaultValue: false)
        p["indentSwitchCaseLabels"] = .boolean(description: "Indent case labels relative to switch.", defaultValue: false)
        p["spacesAroundRangeFormationOperators"] = .boolean(description: "Force spaces around ... and ..<.", defaultValue: false)
        p["multiElementCollectionTrailingCommas"] = .boolean(description: "Trailing commas in multi-element collection literals.", defaultValue: true)
        p["indentBlankLines"] = .boolean(description: "Add indentation whitespace to blank lines.", defaultValue: false)
        p["multilineTrailingCommaBehavior"] = .stringEnum(description: "Trailing comma handling in multiline lists.", values: ["alwaysUsed", "neverUsed", "keptAsWritten"], defaultValue: "keptAsWritten")
        p["reflowMultilineStringLiterals"] = .stringEnum(description: "Multiline string literal reflow mode.", values: ["never", "onlyLinesOverLength", "always"], defaultValue: "never")

        return p
    }

    /// Returns the JSON Schema object variant for a rule that has config options,
    /// including the `severity` property. Returns `nil` for rules without options.
    private func ruleOptionsSchema(for ruleName: String, isOptIn: Bool) -> JSONSchemaNode? {
        let severityProp = JSONSchemaNode.stringEnum(
            description: "Rule severity: warn, error, or off.",
            values: ["warn", "error", "off"],
            defaultValue: isOptIn ? "off" : "warn"
        )

        switch ruleName {
        case "FileScopedDeclarationPrivacy":
            return .object(
                description: "",
                properties: [
                    "severity": severityProp,
                    "accessLevel": .stringEnum(
                        description: "Access level for file-scoped private declarations.",
                        values: ["private", "fileprivate"],
                        defaultValue: "private"
                    ),
                ]
            )
        case "NoAssignmentInExpressions":
            return .object(
                description: "",
                properties: [
                    "severity": severityProp,
                    "allowedFunctions": .stringArray(
                        description: "Functions where embedded assignments are allowed.",
                        defaultValue: ["XCTAssertNoThrow"]
                    ),
                ]
            )
        case "SortImports":
            return .object(
                description: "",
                properties: [
                    "severity": severityProp,
                    "includeConditionalImports": .boolean(
                        description: "Sort imports within #if blocks.",
                        defaultValue: false
                    ),
                    "shouldGroupImports": .boolean(
                        description: "Separate imports into groups by type.",
                        defaultValue: true
                    ),
                ]
            )
        case "CapitalizeAcronyms":
            return .object(
                description: "",
                properties: [
                    "severity": severityProp,
                    "words": .stringArray(
                        description: "Acronyms to capitalize (fully uppercased).",
                        defaultValue: [
                            "API", "CSS", "DNS", "FTP", "GIF", "HTML", "HTTP", "HTTPS",
                            "ID", "JPEG", "JSON", "PDF", "PNG", "RGB", "RGBA",
                            "SQL", "SSH", "TCP", "UDP", "URL", "UUID", "XML",
                        ]
                    ),
                ]
            )
        case "NoExtensionAccessLevel":
            return .object(
                description: "",
                properties: [
                    "severity": severityProp,
                    "placement": .stringEnum(
                        description: "Where to place access control modifiers.",
                        values: ["onDeclarations", "onExtension"],
                        defaultValue: "onDeclarations"
                    ),
                ]
            )
        case "PatternLetPlacement":
            return .object(
                description: "",
                properties: [
                    "severity": severityProp,
                    "placement": .stringEnum(
                        description: "Where to place let/var in case patterns.",
                        values: ["eachBinding", "outerPattern"],
                        defaultValue: "eachBinding"
                    ),
                ]
            )
        case "URLMacro":
            return .object(
                description: "",
                properties: [
                    "severity": severityProp,
                    "macroName": .string(description: "Macro name, e.g. \"#URL\". Omit to disable."),
                    "moduleName": .string(description: "Module to import for the macro."),
                ]
            )
        case "FileHeader":
            return .object(
                description: "",
                properties: [
                    "severity": severityProp,
                    "text": .string(
                        description: "Header text. Omit to disable, empty string to remove headers."
                    ),
                ]
            )
        default:
            return nil
        }
    }
}
