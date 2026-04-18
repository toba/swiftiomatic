/// Maximum line length before wrapping.
package struct LineLength: LayoutDescriptor {
    package static let key = "lineLength"
    package static let description = "Maximum line length before wrapping."
    package static let defaultValue = 100
    package static let schema: ConfigProperty.Schema = .integer(
        description: description, defaultValue: defaultValue, minimum: 1
    )
    package static let keyPath = \Configuration.lineLength
}
