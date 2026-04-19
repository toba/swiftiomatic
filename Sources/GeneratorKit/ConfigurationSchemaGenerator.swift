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

import ConfigurationKit
import Foundation
import SwiftiomaticKit

/// Generates `schema.json` by encoding a `JSONSchemaNode` tree.
///
/// Rule descriptions are sourced from `ConfigurableCollector` (extracted from DocC comments)
/// so they stay in sync with rule implementations.
package final class ConfigurationSchemaGenerator: FileGenerator {
    let collector: ConfigurableCollector

    package init(collector: ConfigurableCollector) {
        self.collector = collector
    }

    package func generateContent() -> String {
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
        root.description = "Configuration for Swiftiomatic formatter and linter."
        root.type = "object"
        root.additionalProperties = false

        var schema: [String: JSONSchemaNode] = [:]

        schema["$schema"] = .string(description: "JSON Schema reference URL.")
        schema["version"] = .integer(
            description: "Configuration format version.",
            defaultValue: 4,
            minimum: 1
        )

        // Root-level pretty-print settings.
        for (key, node) in rootSettingsSchema() {
            schema[key] = node
        }

        // Config groups at root level.
        for (key, node) in groupSchemas() {
            schema[key] = node
        }

        // All rules at root level (ungrouped).
        let allRules = collector.allLinters
            .sorted(by: { $0.ruleName < $1.ruleName })
        for rule in allRules {
            schema[rule.ruleName] = ruleSchemaNode(for: rule)
        }

        root.properties = schema
        return root
    }

    private func ruleSchemaNode(for rule: ConfigurableCollector.DetectedRule) -> JSONSchemaNode {
        var desc = rule.description ?? (rule.canFormat ? "Format rule." : "Lint rule.")
        if rule.defaultHandling == "off" { desc += " [opt-in]" }

        let modeValues =
            rule.canFormat
            ? ["autoFix", "warn", "error", "off"]
            : ["warn", "error", "off"]
        let defaultMode = jsonMode(for: rule.defaultHandling)

        let modeVariant = JSONSchemaNode.stringEnum(
            description: desc,
            values: modeValues,
            defaultValue: defaultMode
        )

        if let optionsSchema = ruleOptionsSchema(
            for: rule.ruleName,
            canFormat: rule.canFormat,
            defaultHandling: rule.defaultHandling
        ) {
            var node = JSONSchemaNode()
            node.description = desc
            node.oneOf = [modeVariant, optionsSchema]
            return node
        } else {
            return modeVariant
        }
    }

    private func rootSettingsSchema() -> [String: JSONSchemaNode] {
        var schema: [String: JSONSchemaNode] = [:]

        // Derive schema from LayoutDescriptor types.
        for descriptor in LayoutSettings.rootSettings {
            schema[descriptor.key] = .string(description: descriptor.description)
        }

        // Override indentation with its oneOf schema (spaces/tabs).
        var indent = JSONSchemaNode()
        indent.description = IndentationSetting.description
        indent.defaultValue = .object(["spaces": .int(2)])
        var spacesVariant = JSONSchemaNode.object(
            description: "Indent with spaces.",
            properties: [
                "spaces": .integer(
                    description: "Number of spaces per indent level.",
                    defaultValue: 2,
                    minimum: 1
                )
            ]
        )
        spacesVariant.required = ["spaces"]
        var tabsVariant = JSONSchemaNode.object(
            description: "Indent with tabs.",
            properties: [
                "tabs": .integer(
                    description: "Number of tabs per indent level.",
                    defaultValue: 1,
                    minimum: 1
                )
            ]
        )
        tabsVariant.required = ["tabs"]
        indent.oneOf = [spacesVariant, tabsVariant]
        schema["indentation"] = indent

        return schema
    }

    private func groupSchemas() -> [String: JSONSchemaNode] {
        // Build group → rules mapping from the collector (mirrors ConfigurationRegistryGenerator logic).
        var groupedRules: [ConfigurationGroup: [ConfigurableCollector.DetectedRule]] = [:]
        for rule in collector.allLinters {
            guard let group = rule.group else { continue }
            groupedRules[group, default: []].append(rule)
        }

        var groups: [String: JSONSchemaNode] = [:]

        for group in ConfigurationGroup.Key.allCases.map({ ConfigurationGroup($0) }) {
            var properties: [String: JSONSchemaNode] = [:]

            // Non-rule settings from LayoutDescriptor types.
            for descriptor in LayoutSettings.settings(in: group) {
                properties[descriptor.key] = .string(description: descriptor.description)
            }

            // Rules within the group.
            if let rules = groupedRules[group] {
                for rule in rules.sorted(by: { $0.ruleName < $1.ruleName }) {
                    let option = ConfigurationGenerator.optionName(for: rule.ruleName)
                    let modeValues =
                        rule.canFormat
                        ? ["autoFix", "warn", "error", "off"]
                        : ["warn", "error", "off"]
                    let defaultMode = jsonMode(for: rule.defaultHandling)
                    properties[option] = .stringEnum(
                        description: rule.description ?? rule.ruleName,
                        values: modeValues,
                        defaultValue: defaultMode
                    )
                }
            }

            guard !properties.isEmpty else { continue }
            groups[group.key.rawValue] = .object(
                description: "\(group.key.rawValue) rule group.",
                properties: properties
            )
        }

        return groups
    }

    /// Returns the JSON Schema object variant for a rule that has config options,
    /// including the `mode` property. Returns `nil` for rules without options.
    private func ruleOptionsSchema(for ruleName: String, canFormat: Bool, defaultHandling: String)
        -> JSONSchemaNode?
    {
        // TODO: Derive rule config schemas from Configurable metadata
        nil
    }

    /// Maps a `RuleHandling` case name to its JSON-encoded string.
    private func jsonMode(for defaultHandling: String) -> String {
        switch defaultHandling {
        case "fix": "autoFix"
        case "warning": "warn"
        case "error": "error"
        case "off": "off"
        default: "warn"
        }
    }

}
