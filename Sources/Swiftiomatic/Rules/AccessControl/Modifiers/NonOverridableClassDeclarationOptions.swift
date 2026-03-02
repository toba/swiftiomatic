struct NonOverridableClassDeclarationOptions: SeverityBasedRuleOptions {
    enum FinalClassModifier: String, AcceptableByOptionElement {
        case finalClass = "final class"
        case `static`
    }

    @OptionElement(key: "severity")
    var severityConfiguration = SeverityOption<Parent>.warning
    @OptionElement(key: "final_class_modifier")
    private(set) var finalClassModifier = FinalClassModifier.finalClass
    typealias Parent = NonOverridableClassDeclarationRule
    mutating func apply(configuration: [String: Any]) throws(SwiftiomaticError) {
        try applySeverityIfPresent(configuration)
        if let value = configuration[$finalClassModifier.key] {
            try finalClassModifier.apply(value, ruleID: Parent.identifier)
        }
        warnAboutUnknownKeys(in: configuration)
        validate()
    }
}
