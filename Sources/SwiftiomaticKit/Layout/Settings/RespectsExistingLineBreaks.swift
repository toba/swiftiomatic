/// Preserve discretionary line breaks.
package struct RespectsExistingLineBreaks: LayoutDescriptor {
    package static let key = "respectsExistingLineBreaks"
    package static let description = "Preserve discretionary line breaks."
    package static let defaultValue = true
    package static let schema: ConfigProperty.Schema = .bool(
        description: description, defaultValue: defaultValue
    )
    package static let keyPath = \Configuration.respectsExistingLineBreaks
}
