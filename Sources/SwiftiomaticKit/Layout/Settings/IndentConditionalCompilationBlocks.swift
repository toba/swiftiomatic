/// Indent #if/#elseif/#else blocks.
package struct IndentConditionalCompilationBlocks: LayoutDescriptor {
    package static let key = "conditionalCompilationBlocks"
    package static let group: ConfigGroup? = .indentation
    package static let description = "Indent #if/#elseif/#else blocks."
    package static let defaultValue = true
    package static let schema: ConfigProperty.Schema = .bool(
        description: description, defaultValue: defaultValue
    )
    package static let keyPath = \Configuration.indentConditionalCompilationBlocks
}
