/// Wraps a ``FormatRule`` to produce a ``RuleConfigurationEntry``
struct FormatRuleConfigurationAdapter {
    private let rule: FormatRule
    private let isDefault: Bool

    init(_ rule: FormatRule, isDefault: Bool) {
        self.rule = rule
        self.isDefault = isDefault
    }

    /// Convert this format rule adapter to a concrete ``RuleConfigurationEntry``
    func toEntry() -> RuleConfigurationEntry {
        RuleConfigurationEntry(
            id: rule.name,
            name: rule.name,
            summary: stripMarkdown(rule.help),
            scope: .format,
            isCorrectable: true,
            isOptIn: !isDefault,
            isDeprecated: rule.isDeprecated,
            deprecationMessage: rule.deprecationMessage,
            examples: RuleExamples(diffMarkdown: rule.examples),
            configurationOptions: configOptions,
        )
    }

    private var configOptions: [ConfigOptionDescriptor] {
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
