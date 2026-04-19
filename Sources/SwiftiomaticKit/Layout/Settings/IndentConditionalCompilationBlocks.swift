/// Indent #if/#elseif/#else blocks.
package struct IndentConditionalCompilationBlocks: LayoutDescriptor {
    package static let key = "conditionalCompilationBlocks"
    package static let group: ConfigurationGroup? = .indentation
    package static let description = "Indent #if/#elseif/#else blocks."
    package static let defaultValue = false
}
