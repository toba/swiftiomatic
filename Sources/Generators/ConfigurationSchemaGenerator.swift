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
@_spi(Internal) import Swiftiomatic
import SwiftiomaticCore

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
        root.id = "https://raw.githubusercontent.com/toba/swiftiomatic/refs/heads/main/schema.json"
        root.title = "Swiftiomatic Configuration"
        root.description = "Configuration for the sm Swift formatter and linter."
        root.type = "object"
        root.additionalProperties = false

        var p: [String: JSONSchemaNode] = [:]

        p["$schema"] = .string(description: "JSON Schema reference URL.")
        p["version"] = .integer(
            description: "Configuration format version.",
            defaultValue: 4,
            minimum: 1
        )

        // Root-level pretty-print settings.
        for (key, node) in rootSettingsSchema() {
            p[key] = node
        }

        // Config groups at root level.
        for (key, node) in groupSchemas() {
            p[key] = node
        }

        // All rules at root level (ungrouped).
        let allRules = ruleCollector.allLinters
            .sorted(by: { $0.ruleName < $1.ruleName })
        for rule in allRules {
            p[rule.ruleName] = ruleSchemaNode(for: rule)
        }

        root.properties = p
        return root
    }

    private func ruleSchemaNode(for rule: RuleCollector.DetectedRule) -> JSONSchemaNode {
        var desc = rule.description ?? (rule.canFormat ? "Format rule." : "Lint rule.")
        if rule.isOptIn { desc += " [opt-in]" }

        let modeValues = rule.canFormat
            ? ["autoFix", "warn", "error", "off"]
            : ["warn", "error", "off"]
        let defaultMode = rule.isOptIn ? "off" : (rule.canFormat ? "autoFix" : "warn")

        let modeVariant = JSONSchemaNode.stringEnum(
            description: desc,
            values: modeValues,
            defaultValue: defaultMode
        )

        if let optionsSchema = ruleOptionsSchema(for: rule.ruleName, canFormat: rule.canFormat, isOptIn: rule.isOptIn) {
            var node = JSONSchemaNode()
            node.description = desc
            node.oneOf = [modeVariant, optionsSchema]
            return node
        } else {
            return modeVariant
        }
    }

    private func rootSettingsSchema() -> [String: JSONSchemaNode] {
        var p: [String: JSONSchemaNode] = [:]

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
        p["prioritizeKeepingFunctionOutputTogether"] = .boolean(description: "Keep return type with closing parenthesis.", defaultValue: false)
        p["spacesAroundRangeFormationOperators"] = .boolean(description: "Force spaces around ... and ..<.", defaultValue: false)
        p["multiElementCollectionTrailingCommas"] = .boolean(description: "Trailing commas in multi-element collection literals.", defaultValue: true)
        p["multilineTrailingCommaBehavior"] = .stringEnum(description: "Trailing comma handling in multiline lists.", values: ["alwaysUsed", "neverUsed", "keptAsWritten"], defaultValue: "keptAsWritten")
        p["reflowMultilineStringLiterals"] = .stringEnum(description: "Multiline string literal reflow mode.", values: ["never", "onlyLinesOverLength", "always"], defaultValue: "never")

        return p
    }

    private func groupSchemas() -> [String: JSONSchemaNode] {
        // Build group → rules mapping from the collector (mirrors RuleRegistryGenerator logic).
        var groupedRules: [ConfigGroup: [RuleCollector.DetectedRule]] = [:]
        for rule in ruleCollector.allLinters {
            guard let group = rule.group else { continue }
            groupedRules[group, default: []].append(rule)
        }

        var groups: [String: JSONSchemaNode] = [:]

        for group in ConfigGroup.allCases {
            var properties: [String: JSONSchemaNode] = [:]

            // Non-rule settings from ConfigRepresentable.
            for prop in group.configProperties {
                properties[prop.key] = schemaNode(from: prop.schema)
            }

            // Rules within the group.
            if let rules = groupedRules[group] {
                for rule in rules.sorted(by: { $0.ruleName < $1.ruleName }) {
                    let option = RuleRegistryGenerator.optionName(for: rule.ruleName)
                    let modeValues = rule.canFormat
                        ? ["autoFix", "warn", "error", "off"]
                        : ["warn", "error", "off"]
                    let defaultMode = rule.isOptIn ? "off" : (rule.canFormat ? "autoFix" : "warn")
                    properties[option] = .stringEnum(
                        description: rule.description ?? rule.ruleName,
                        values: modeValues, defaultValue: defaultMode
                    )
                }
            }

            guard !properties.isEmpty else { continue }
            groups[group.rawValue] = .object(
                description: "\(group.rawValue) rule group.",
                properties: properties
            )
        }

        return groups
    }

    /// Returns the JSON Schema object variant for a rule that has config options,
    /// including the `mode` property. Returns `nil` for rules without options.
    private func ruleOptionsSchema(for ruleName: String, canFormat: Bool, isOptIn: Bool) -> JSONSchemaNode? {
        guard let configProperties = Configuration.ruleConfigSchemas[ruleName] else { return nil }

        let modeValues = canFormat ? ["autoFix", "warn", "error", "off"] : ["warn", "error", "off"]
        let defaultMode = isOptIn ? "off" : (canFormat ? "autoFix" : "warn")
        let modeProp = JSONSchemaNode.stringEnum(
            description: "Rule mode.", values: modeValues, defaultValue: defaultMode
        )

        var props: [String: JSONSchemaNode] = ["mode": modeProp]
        for prop in configProperties {
            props[prop.key] = schemaNode(from: prop.schema)
        }
        return .object(description: "", properties: props)
    }

    private func schemaNode(from schema: ConfigProperty.Schema) -> JSONSchemaNode {
        switch schema {
        case .bool(let desc, let def): .boolean(description: desc, defaultValue: def)
        case .integer(let desc, let def, let min): .integer(description: desc, defaultValue: def, minimum: min)
        case .string(let desc): .string(description: desc)
        case .stringEnum(let desc, let vals, let def): .stringEnum(description: desc, values: vals, defaultValue: def)
        case .stringArray(let desc, let def): .stringArray(description: desc, defaultValue: def)
        }
    }
}
