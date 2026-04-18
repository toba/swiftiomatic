/// Keep return type with closing parenthesis.
package struct PrioritizeKeepingFunctionOutputTogether: LayoutDescriptor {
    package static let key = "prioritizeKeepingFunctionOutputTogether"
    package static let description = "Keep return type with closing parenthesis."
    package static let defaultValue = false
    package static let schema: ConfigProperty.Schema = .bool(
        description: description, defaultValue: defaultValue
    )
    package static let keyPath = \Configuration.prioritizeKeepingFunctionOutputTogether
}
