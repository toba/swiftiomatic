/// Maximum consecutive blank lines.
package struct MaximumBlankLines: LayoutDescriptor {
    package static let key = "maximumBlankLines"
    package static let group: ConfigGroup? = .blankLines
    package static let description = "Maximum consecutive blank lines."
    package static let defaultValue = 1
    package static let schema: ConfigProperty.Schema = .integer(
        description: description, defaultValue: defaultValue, minimum: 0
    )
    package static let keyPath = \Configuration.maximumBlankLines
}
