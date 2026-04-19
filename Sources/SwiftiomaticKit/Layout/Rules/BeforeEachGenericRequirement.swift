/// Break before each generic requirement when wrapping.
package struct BeforeEachGenericRequirement: LayoutRule {
    package static let key = "beforeEachGenericRequirement"
    package static let group: ConfigurationGroup? = .lineBreaks
    package static let description = "Break before each generic requirement when wrapping."
    package static let defaultValue = false
}

// MARK: - TokenStream

extension TokenStream {
    /// Returns the group consistency that should be used for generic requirement lists based on
    /// the user's current configuration.
    func genericRequirementListConsistency() -> GroupBreakStyle {
        return config[BeforeEachGenericRequirement.self] ? .consistent : .inconsistent
    }
}
