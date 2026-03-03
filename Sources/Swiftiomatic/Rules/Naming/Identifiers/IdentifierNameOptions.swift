struct IdentifierNameOptions: RuleOptions {
    private static let defaultOperators = [
        "/", "=", "-", "+", "!", "*", "|", "^", "~", "?", ".", "%", "<", ">", "&",
    ]

    @OptionElement(isInline: true)
    private(set) var nameConfiguration = NameOptions<Parent>(
        minLengthWarning: 3,
        minLengthError: 2,
        maxLengthWarning: 40,
        maxLengthError: 60,
        excluded: ["id"],
    )

    @OptionElement(
        key: "additional_operators", postprocessor: { $0.formUnion(Self.defaultOperators) },
    )
    private(set) var additionalOperators = Set<String>()
    typealias Parent = IdentifierNameRule
    mutating func apply(configuration: [String: Any]) throws(SwiftiomaticError) {
        do {
            try nameConfiguration.apply(configuration, ruleID: Parent.identifier)
        } catch let issue
            where issue == SwiftiomaticError.nothingApplied(ruleID: Parent.identifier)
        {
            // Acceptable. Continue.
        }
        if let value = configuration[$additionalOperators.key] {
            try additionalOperators.apply(value, ruleID: Parent.identifier)
        }
        warnAboutUnknownKeys(in: configuration)
        validate()
    }
}
