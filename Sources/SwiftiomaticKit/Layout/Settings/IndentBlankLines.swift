/// Add indentation whitespace to blank lines.
package struct IndentBlankLines: LayoutDescriptor {
    package static let key = "blankLines"
    package static let group: ConfigurationGroup? = .indentation
    package static let description = "Add indentation whitespace to blank lines."
    package static let defaultValue = false
}
