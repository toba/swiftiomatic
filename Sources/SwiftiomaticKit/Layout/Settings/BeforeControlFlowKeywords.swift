/// Break before else/catch after closing brace.
package struct BeforeControlFlowKeywords: LayoutDescriptor {
    package static let key = "beforeControlFlowKeywords"
    package static let group: ConfigGroup? = .lineBreaks
    package static let description = "Break before else/catch after closing brace."
    package static let defaultValue = false
    package static let schema: ConfigProperty.Schema = .bool(
        description: description, defaultValue: defaultValue
    )
    package static let keyPath = \Configuration.lineBreakBeforeControlFlowKeywords
}
