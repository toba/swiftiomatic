/// Keep return type with closing parenthesis.
package struct KeepFunctionOutputTogether: LayoutRule {
    package static let key = "keepFunctionOutputTogether"
    package static let group: ConfigurationGroup? = .wrap
    package static let description = "Keep return type with closing parenthesis."
    package static let defaultValue = false
}
