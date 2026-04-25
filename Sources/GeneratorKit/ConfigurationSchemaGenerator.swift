import ConfigurationKit
import Foundation

/// Generates `schema.json` by encoding a `JSONSchemaNode` tree.
///
/// Rule descriptions are sourced from `RuleCollector` (extracted from DocC comments)
/// so they stay in sync with rule implementations.
package final class ConfigurationSchemaGenerator: FileGenerator {
    let collector: RuleCollector

    package init(collector: RuleCollector) {
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

        // Define reusable base rule types via $defs.
        root.defs = [
            "ruleBase": Self.ruleBaseSchema(),
            "lintOnlyBase": Self.lintOnlyBaseSchema(),
        ]

        var schema: [String: JSONSchemaNode] = [:]

        schema["$schema"] = .string(description: "JSON Schema reference URL.")
        schema["version"] = .integer(
            description: "Configuration format version.",
            defaultValue: 6,
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
        let allRules = collector.lintingSyntaxRules
            .sorted(by: { $0.configKey < $1.configKey })
        for rule in allRules {
            schema[rule.configKey] = ruleSchemaNode(for: rule)
        }

        root.properties = schema
        return root
    }

    /// Base schema for rewrite rules: `{ "rewrite": bool, "lint": enum }`.
    ///
    /// Does not set `additionalProperties: false` because rules may define
    /// extra configuration properties beyond these base fields.
    private static func ruleBaseSchema() -> JSONSchemaNode {
        // No top-level description: it would override the per-rule description
        // sibling to `allOf` in IDE hovers (Xcode, VS Code).
        .object(
            description: nil,
            properties: [
                "rewrite": .boolean(
                    description: "Whether the rule auto-fixes source code.",
                    defaultValue: true
                ),
                "lint": .stringEnum(
                    description: "Finding severity when the rule is active.",
                    values: lintModeValues,
                    defaultValue: "warn"
                ),
            ],
            additionalProperties: nil
        )
    }

    /// Base schema for lint-only rules: `{ "lint": enum }`.
    ///
    /// Does not set `additionalProperties: false` because rules may define
    /// extra configuration properties beyond this base field.
    private static func lintOnlyBaseSchema() -> JSONSchemaNode {
        .object(
            description: nil,
            properties: [
                "lint": .stringEnum(
                    description: "Finding severity when the rule is active.",
                    values: lintModeValues,
                    defaultValue: "warn"
                )
            ],
            additionalProperties: nil
        )
    }

    private func settingSchemaNode(for setting: RuleCollector.DetectedLayoutRule) -> JSONSchemaNode
    {
        let desc = setting.description ?? setting.configKey
        switch setting.valueType {
            case .boolean:
                var node = JSONSchemaNode()
                node.type = "boolean"
                node.description = desc
                return node
            case .integer:
                var node = JSONSchemaNode()
                node.type = "integer"
                node.description = desc
                return node
            case .string:
                return .string(description: desc)
            case .stringEnum(let values, let defaultValue):
                return .stringEnum(description: desc, values: values, defaultValue: defaultValue)
        }
    }

    private static let lintModeValues = ["warn", "error", "no"]

    private func ruleSchemaNode(for rule: RuleCollector.DetectedSyntaxRule) -> JSONSchemaNode {
        var desc = rule.description ?? (rule.canRewrite ? "Format rule." : "Lint rule.")
        if rule.isOptIn { desc += " [opt-in]" }

        var node = JSONSchemaNode()
        node.description = desc

        var ref = JSONSchemaNode()
        ref.ref = rule.canRewrite ? "#/$defs/ruleBase" : "#/$defs/lintOnlyBase"

        node.allOf = [ref]

        // Add custom properties (enums, strings, arrays) beyond base rewrite/lint.
        if !rule.customProperties.isEmpty {
            node.properties = rule.customProperties.reduce(into: [:]) { dict, prop in
                dict[prop.key] = prop.schemaNode
            }
        }

        // Lint-only rules don't accept `rewrite`. `unevaluatedProperties` (not
        // `additionalProperties`) is required so JSON Schema considers keys
        // contributed by the `$ref` to `lintOnlyBase` and any custom properties.
        if !rule.canRewrite {
            node.unevaluatedProperties = false
        }

        return node
    }

    private func rootSettingsSchema() -> [String: JSONSchemaNode] {
        var schema: [String: JSONSchemaNode] = [:]

        for setting in collector.layoutRules where setting.group == nil {
            schema[setting.configKey] = settingSchemaNode(for: setting)
        }

        return schema
    }

    /// The `unit` setting uses a `oneOf` schema (spaces or tabs object) instead
    /// of a simple type, since its value type is the `Indent` enum.
    private static func indentationUnitSchema() -> JSONSchemaNode {
        let desc = "Indentation unit: exactly one of spaces or tabs."
        var node = JSONSchemaNode()
        node.description = desc
        node.defaultValue = .object(["spaces": .int(2)])
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
        node.oneOf = [spacesVariant, tabsVariant]
        return node
    }

    private func groupSchemas() -> [String: JSONSchemaNode] {
        var groupedRules: [ConfigurationGroup: [RuleCollector.DetectedSyntaxRule]] = [:]
        for rule in collector.lintingSyntaxRules {
            guard let group = rule.group else { continue }
            groupedRules[group, default: []].append(rule)
        }

        var groups: [String: JSONSchemaNode] = [:]

        for group in ConfigurationGroup.Key.allCases.map({ ConfigurationGroup($0) }) {
            var properties: [String: JSONSchemaNode] = [:]

            for setting in collector.layoutRules where setting.group == group {
                if setting.configKey == "unit" {
                    properties[setting.configKey] = Self.indentationUnitSchema()
                } else {
                    properties[setting.configKey] = settingSchemaNode(for: setting)
                }
            }

            if let rules = groupedRules[group] {
                for rule in rules.sorted(by: { $0.configKey < $1.configKey }) {
                    properties[rule.configKey] = ruleSchemaNode(for: rule)
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
}
