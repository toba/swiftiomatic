/// Tab width in spaces for indentation conversion.
package struct TabWidth: LayoutDescriptor {
    package static let key = "tabWidth"
    package static let description = "Tab width in spaces for indentation conversion."
    package static let defaultValue = 8
    package static let schema: ConfigProperty.Schema = .integer(
        description: description, defaultValue: defaultValue, minimum: 1
    )
    package static let keyPath = \Configuration.tabWidth
}
