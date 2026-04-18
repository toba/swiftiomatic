/// Trailing commas in multi-element collection literals.
package struct MultiElementCollectionTrailingCommas: LayoutDescriptor {
    package static let key = "multiElementCollectionTrailingCommas"
    package static let description = "Trailing commas in multi-element collection literals."
    package static let defaultValue = true
    package static let schema: ConfigProperty.Schema = .bool(
        description: description, defaultValue: defaultValue
    )
    package static let keyPath = \Configuration.multiElementCollectionTrailingCommas
}
