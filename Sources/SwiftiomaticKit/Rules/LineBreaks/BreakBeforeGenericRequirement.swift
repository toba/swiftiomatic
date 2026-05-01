/// Break before each generic requirement when wrapping.
package struct BreakBeforeGenericRequirement: LayoutRule {
    package static let key = "breakBeforeGenericRequirement"
    package static let group: ConfigurationGroup? = .lineBreaks
    package static let description = "Break before each generic requirement when wrapping."
    package static let defaultValue = false
}

extension TokenStream {
    /// Returns the group consistency that should be used for generic requirement lists based on the
    /// user's current configuration.
    func genericRequirementListConsistency() -> GroupBreakStyle {
        config[BreakBeforeGenericRequirement.self] ? .consistent : .inconsistent
    }
}
