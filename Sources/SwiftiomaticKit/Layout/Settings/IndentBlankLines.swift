/// Add indentation whitespace to blank lines.
package struct IndentBlankLines: LayoutDescriptor {
    package static let key = "blankLines"
    package static let group: ConfigGroup? = .indentation
    package static let description = "Add indentation whitespace to blank lines."
    package static let defaultValue = false
    package static let schema: ConfigProperty.Schema = .bool(
        description: description, defaultValue: defaultValue
    )
    package static let keyPath = \Configuration.indentBlankLines
}
