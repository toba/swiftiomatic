import Foundation

/// Wraps a lint ``Rule`` type to expose it as a ``RuleConfiguration``
struct LintRuleConfigurationAdapter: RuleConfiguration {
    private let ruleType: any Rule.Type

    init(_ ruleType: any Rule.Type) {
        self.ruleType = ruleType
    }

    var id: String { ruleType.identifier }
    var name: String { ruleType.description.name } // TODO: migrate to configuration
    var summary: String { ruleType.description.description } // TODO: migrate to configuration
    var rationale: String? { ruleType.description.rationale } // TODO: migrate to configuration
    var scope: Scope { ruleType.ruleScope }

    var isCorrectable: Bool {
        ruleType is any CorrectableRule.Type
    }

    var isOptIn: Bool { ruleType.isOptIn }

    var isDeprecated: Bool {
        let desc = ruleType.description
        return !desc.deprecatedAliases.isEmpty && desc.deprecatedAliases.contains(desc.identifier)
    }

    var deprecationMessage: String? { nil }
    var requiresSourceKit: Bool { ruleType.description.requiresSourceKit } // TODO: migrate to configuration
    var requiresCompilerArguments: Bool { ruleType.description.requiresCompilerArguments } // TODO: migrate to configuration

    var isCrossFile: Bool {
        ruleType is any CollectingRuleMarker.Type
    }

    var canEnrichAsync: Bool {
        ruleType is any AsyncEnrichableRule.Type
    }

    var examples: RuleExamples {
        let desc = ruleType.description
        let nonTriggering = desc.nonTriggeringExamples.map {
            CodeExample(code: $0.code)
        }
        let triggering = desc.triggeringExamples.map {
            CodeExample(code: $0.code)
        }
        let corrections = desc.corrections.map { before, after in
            CorrectionExample(
                before: before.code,
                after: after.code,
            )
        }
        return RuleExamples(
            nonTriggering: nonTriggering,
            triggering: triggering,
            corrections: corrections,
        )
    }

    var configurationOptions: [ConfigOptionDescriptor] {
        let rule = ruleType.init()
        let desc = rule.createConfigurationDescription()
        guard desc.hasContent else { return [] }
        return desc.toConfigOptionDescriptors()
    }

    var relatedRuleIDs: [String] {
        Array(ruleType.description.deprecatedAliases) // TODO: migrate to configuration
    }
}

extension RuleOptionsDescription {
    /// Convert this options description into uniform ``ConfigOptionDescriptor`` values
    func toConfigOptionDescriptors() -> [ConfigOptionDescriptor] {
        // Access the options through the Documentable interface
        // We parse the YAML representation to extract key-value pairs
        let yamlString = yaml()
        guard !yamlString.isEmpty else { return [] }

        return yamlString.components(separatedBy: "\n").compactMap { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { return nil }
            let parts = trimmed.split(separator: ":", maxSplits: 1)
            guard parts.count == 2 else { return nil }
            let key = String(parts[0]).trimmingCharacters(in: .whitespaces)
            let value = String(parts[1]).trimmingCharacters(in: .whitespaces)
            let valueType = inferValueType(from: value)
            return ConfigOptionDescriptor(
                key: key,
                displayName: key.replacingOccurrences(of: "_", with: " ").capitalized,
                help: "",
                valueType: valueType,
                defaultValue: value,
            )
        }
    }

    private func inferValueType(from value: String) -> ConfigValueType {
        if value == "true" || value == "false" {
            return .bool
        }
        if value == "warning" || value == "error" {
            return .severity
        }
        if Int(value) != nil {
            return .int
        }
        if Double(value) != nil {
            return .float
        }
        if value.hasPrefix("[") {
            return .list
        }
        return .string
    }
}
