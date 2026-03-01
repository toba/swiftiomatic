struct ModifierOrderConfiguration: SeverityBasedRuleOptions {
    @ConfigurationElement(key: "severity")
    var severityConfiguration = SeverityConfiguration<Parent>(.warning)
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
    mutating func apply(configuration: [String: Any]) throws(SwiftiomaticError) {
        try applySeverityIfPresent(configuration)
        if let value = configuration[$preferredModifierOrder.key] {
            try preferredModifierOrder.apply(value, ruleID: Parent.identifier)
        }
        warnAboutUnknownKeys(in: configuration)
        validate()
    }
}

extension SwiftDeclarationAttributeKind.ModifierGroup: AcceptableByConfigurationElement {
    init(fromAny value: Any, context ruleID: String) throws(SwiftiomaticError) {
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
