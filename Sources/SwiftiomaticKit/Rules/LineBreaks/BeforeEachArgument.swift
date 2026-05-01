/// Break before each argument when wrapping.
package struct BeforeEachArgument: LayoutRule {
    package static let key = "beforeEachArgument"
    package static let group: ConfigurationGroup? = .lineBreaks
    package static let description = "Break before each argument when wrapping."
    package static let defaultValue = false
}

extension TokenStream {
    /// Returns the group consistency that should be used for argument lists based on the user's
    /// current configuration.
    func argumentListConsistency() -> GroupBreakStyle {
        config[BeforeEachArgument.self] ? .consistent : .inconsistent
    }
}
