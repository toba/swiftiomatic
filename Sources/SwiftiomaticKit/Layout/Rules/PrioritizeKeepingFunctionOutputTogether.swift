/// Keep return type with closing parenthesis.
package struct PrioritizeKeepingFunctionOutputTogether: LayoutRule {
    package static let key = "prioritizeKeepingFunctionOutputTogether"
    package static let group: ConfigurationGroup? = .wrap
    package static let description = "Keep return type with closing parenthesis."
    package static let defaultValue = false
}
