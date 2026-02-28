import SourceKittenFramework

struct ModifierOrderConfiguration: SeverityBasedRuleConfiguration {
    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "preferred_modifier_order")
    private(set) var preferredModifierOrder: [SwiftDeclarationAttributeKind.ModifierGroup] = [
        .override,
        .isolation,
        .acl,
        .setterACL,
        .dynamic,
        .mutators,
        .lazy,
        .final,
        .required,
        .convenience,
        .typeMethods,
        .owned,
    ]
    typealias Parent = ModifierOrderRule
    mutating func apply(configuration: Any) throws(Issue) {
        if $preferredModifierOrder.key.isEmpty {
            $preferredModifierOrder.key = "preferred_modifier_order"
        }
        do {
            try severityConfiguration.apply(configuration, ruleID: Parent.identifier)
        } catch let issue where issue == Issue.nothingApplied(ruleID: Parent.identifier) {
            // Acceptable. Continue.
        }
        guard let configuration = configuration as? [String: Any] else {
            return
        }
        if let value = configuration[$preferredModifierOrder.key] {
            try preferredModifierOrder.apply(value, ruleID: Parent.identifier)
        }
        if !supportedKeys.isSuperset(of: configuration.keys) {
            let unknownKeys = Set(configuration.keys).subtracting(supportedKeys)
            Issue.invalidConfigurationKeys(ruleID: Parent.identifier, keys: unknownKeys).print()
        }
        try validate()
    }
}

extension SwiftDeclarationAttributeKind.ModifierGroup: AcceptableByConfigurationElement {
    init(fromAny value: Any, context ruleID: String) throws(Issue) {
        if let value = value as? String, let newSelf = Self(rawValue: value),
           newSelf != .atPrefixed
        {
            self = newSelf
        } else {
            throw .invalidConfiguration(ruleID: ruleID)
        }
    }

    func asOption() -> OptionType {
        .symbol(rawValue)
    }
}
