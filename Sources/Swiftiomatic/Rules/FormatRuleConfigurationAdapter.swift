/// Wraps a ``FormatRule`` to expose it as a ``RuleConfiguration``
struct FormatRuleConfigurationAdapter: RuleConfiguration {
    private let rule: FormatRule
    private let isDefault: Bool

    init(_ rule: FormatRule, isDefault: Bool) {
        self.rule = rule
        self.isDefault = isDefault
    }

    var id: String { rule.name }
    var name: String { rule.name }
    var summary: String { stripMarkdown(rule.help) }
    var rationale: String? { nil }
    var scope: Scope { .format }
    var isCorrectable: Bool { true }
    var isOptIn: Bool { !isDefault }
    var isDeprecated: Bool { rule.isDeprecated }
    var deprecationMessage: String? { rule.deprecationMessage }
    var requiresSourceKit: Bool { false }
    var requiresCompilerArguments: Bool { false }
    var isCrossFile: Bool { false }
    var canEnrichAsync: Bool { false }

    var examples: RuleExamples {
        RuleExamples(diffMarkdown: rule.examples)
    }

    var configurationOptions: [ConfigOptionDescriptor] {
        let allOptions = rule.options + rule.sharedOptions
        let descriptorsByProperty = Dictionary(
            Descriptors.all.map { ($0.propertyName, $0) },
            uniquingKeysWith: { first, _ in first },
        )
        return allOptions.compactMap { optionName in
            guard let descriptor = descriptorsByProperty[optionName] else {
                return nil
            }
            return descriptor.toConfigOptionDescriptor()
        }
    }

    var relatedRuleIDs: [String] { [] }
}

extension OptionDescriptor {
    /// Convert this format option descriptor to a ``ConfigOptionDescriptor``
    func toConfigOptionDescriptor() -> ConfigOptionDescriptor {
        ConfigOptionDescriptor(
            key: argumentName,
            displayName: displayName,
            help: help,
            valueType: type.toConfigValueType(),
            defaultValue: defaultArgument,
            validValues: validArguments,
        )
    }
}

extension OptionDescriptor.ArgumentType {
    /// Convert this format option argument type to a ``ConfigValueType``
    func toConfigValueType() -> ConfigValueType {
        switch self {
            case .binary:
                .bool
            case .enum:
                .enum
            case .text:
                .string
            case .int:
                .int
            case .array:
                .list
            case .set:
                .list
        }
    }
}
