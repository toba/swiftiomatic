/// Indentation unit (spaces or tabs).
package struct IndentationSetting: LayoutDescriptor {
    package static let key = "indentation"
    package static let description = "Indentation unit: exactly one of spaces or tabs."
    package static let defaultValue: Indent = .spaces(2)
    // The actual schema for this setting is a oneOf (spaces/tabs) handled
    // as a special case in the schema generator. This placeholder ensures
    // the setting participates in the descriptor registry.
    package static let schema: ConfigProperty.Schema = .string(description: description)
    package static let keyPath = \Configuration.indentation
}
