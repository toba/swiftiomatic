/// Indentation unit (spaces or tabs).
package struct IndentationSetting: LayoutDescriptor {
    package static let key = "unit"
    package static let group: ConfigurationGroup? = .indentation
    package static let description = "Indentation unit: exactly one of spaces or tabs."
    package static let defaultValue: Indent = .spaces(4)
}
