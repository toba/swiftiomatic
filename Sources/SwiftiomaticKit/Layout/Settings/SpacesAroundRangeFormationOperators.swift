/// Force spaces around range operators.
package struct SpacesAroundRangeFormationOperators: LayoutDescriptor {
    package static let key = "spacesAroundRangeFormationOperators"
    package static let description = "Force spaces around ... and ..<."
    package static let defaultValue = false
    package static let schema: ConfigProperty.Schema = .bool(
        description: description, defaultValue: defaultValue
    )
    package static let keyPath = \Configuration.spacesAroundRangeFormationOperators
}
