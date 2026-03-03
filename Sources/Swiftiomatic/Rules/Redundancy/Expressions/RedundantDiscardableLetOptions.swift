struct RedundantDiscardableLetOptions: SeverityBasedRuleOptions {
    @OptionElement(key: "severity")
    var severityConfiguration = SeverityOption<Parent>(.warning)
    @OptionElement(key: "ignore_swiftui_view_bodies")
    private(set) var ignoreSwiftUIViewBodies = false
    typealias Parent = RedundantDiscardableLetRule
    mutating func apply(configuration: [String: Any]) throws(SwiftiomaticError) {
        try applySeverityIfPresent(configuration)
        if let value = configuration[$ignoreSwiftUIViewBodies.key] {
            try ignoreSwiftUIViewBodies.apply(value, ruleID: Parent.identifier)
        }
        warnAboutUnknownKeys(in: configuration)
        validate()
    }
}
